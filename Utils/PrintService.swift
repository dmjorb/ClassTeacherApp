import UIKit

// 通用打印服务 — 支持 HTML 内容 AirPrint
class PrintService {
    static let shared = PrintService()

    private init() {}

    // 打印 HTML 内容
    func printHTML(title: String, html: String) {
        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = title
        printController.printInfo = printInfo

        // 用 UIMarkupTextPrintFormatter 渲染 HTML
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        formatter.perPageContentInsets = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36)
        printController.printFormatter = formatter

        printController.present(animated: true) { _, completed, error in
            if let error = error {
                print("打印失败: \(error.localizedDescription)")
            }
        }
    }

    // 打印纯文本
    func printText(title: String, text: String) {
        let html = """
        <html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system, sans-serif; font-size: 14px; line-height: 1.6; color: #1c1917; }
        h1 { font-size: 22px; text-align: center; margin-bottom: 20px; }
        </style></head><body><h1>\(title)</h1>\(text.replacingOccurrences(of: "\n", with: "<br>"))</body></html>
        """
        printHTML(title: title, html: html)
    }
}

// MARK: - 班主任工作台专用打印模板
extension PrintService {

    // 课表打印
    func printSchedule(className: String, weekDays: [String], periods: [Int], schedule: [[String?]]) {
        var html = """
        <html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system, sans-serif; color: #1c1917; }
        h1 { font-size: 20px; text-align: center; margin-bottom: 4px; }
        .subtitle { text-align: center; color: #78716c; font-size: 12px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; font-size: 12px; }
        th, td { border: 1px solid #d6d3d1; padding: 10px 6px; text-align: center; }
        th { background: #f5f2ed; font-weight: 600; }
        .period { width: 50px; background: #fafaf9; font-weight: 600; color: #78716c; }
        .empty { color: #d6d3d1; }
        </style></head><body>
        <h1>\(className) 课程表</h1>
        <div class="subtitle">打印时间：\(Self.currentDateString())</div>
        <table>
        <tr><th class="period">节次</th>
        """

        for day in weekDays {
            html += "<th>\(day)</th>"
        }
        html += "</tr>"

        for (rowIdx, period) in periods.enumerated() {
            html += "<tr><td class=\"period\">第\(period)节</td>"
            for colIdx in 0..<weekDays.count {
                if rowIdx < schedule.count && colIdx < schedule[rowIdx].count,
                   let subject = schedule[rowIdx][colIdx], !subject.isEmpty {
                    html += "<td>\(subject)</td>"
                } else {
                    html += "<td class=\"empty\">—</td>"
                }
            }
            html += "</tr>"
        }

        html += "</table></body></html>"
        printHTML(title: "\(className)课程表", html: html)
    }

    // 值日表打印
    func printDuty(className: String, groups: [(name: String, members: [String])], currentGroupIndex: Int) {
        var html = """
        <html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system, sans-serif; color: #1c1917; }
        h1 { font-size: 20px; text-align: center; margin-bottom: 4px; }
        .subtitle { text-align: center; color: #78716c; font-size: 12px; margin-bottom: 20px; }
        .group { margin-bottom: 16px; page-break-inside: avoid; }
        .group-title { font-size: 15px; font-weight: 600; color: #c2410c; margin-bottom: 6px; padding-bottom: 4px; border-bottom: 2px solid #c2410c; }
        .group-title.current { color: #16a34a; border-bottom-color: #16a34a; }
        .members { font-size: 13px; line-height: 1.8; color: #44403c; }
        .badge { display: inline-block; background: #16a34a; color: white; font-size: 10px; padding: 2px 6px; border-radius: 4px; margin-left: 8px; vertical-align: middle; }
        </style></head><body>
        <h1>\(className) 值日安排表</h1>
        <div class="subtitle">打印时间：\(Self.currentDateString())</div>
        """

        for (idx, group) in groups.enumerated() {
            let isCurrent = idx == currentGroupIndex
            html += """
            <div class="group">
            <div class="group-title \(isCurrent ? "current" : "")">\(group.name)\(isCurrent ? "<span class='badge'>本周</span>" : "")</div>
            <div class="members">\(group.members.joined(separator: "、"))</div>
            </div>
            """
        }

        html += "</body></html>"
        printHTML(title: "\(className)值日表", html: html)
    }

    // 成绩打印
    func printScores(examName: String, className: String, subjects: [String], students: [(name: String, number: String, scores: [Double?])]) {
        var html = """
        <html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system, sans-serif; color: #1c1917; }
        h1 { font-size: 20px; text-align: center; margin-bottom: 4px; }
        .subtitle { text-align: center; color: #78716c; font-size: 12px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; font-size: 11px; }
        th, td { border: 1px solid #d6d3d1; padding: 8px 4px; text-align: center; }
        th { background: #f5f2ed; font-weight: 600; }
        .name { text-align: left; padding-left: 10px; font-weight: 500; }
        .number { color: #a8a29e; font-size: 10px; }
        .total { font-weight: 700; background: #fff7ed; }
        .empty { color: #d6d3d1; }
        .pass { color: #16a34a; }
        .fail { color: #dc2626; }
        </style></head><body>
        <h1>\(examName) 成绩单</h1>
        <div class="subtitle">\(className) · 打印时间：\(Self.currentDateString())</div>
        <table>
        <tr><th style="width:30px">序号</th><th>姓名</th>
        """

        for subject in subjects {
            html += "<th>\(subject)</th>"
        }
        html += "<th class='total'>总分</th></tr>"

        for (idx, student) in students.enumerated() {
            html += "<tr><td>\(idx + 1)</td><td class='name'>\(student.name) <span class='number'>#\(student.number)</span></td>"
            var total: Double = 0
            var hasAny = false
            for score in student.scores {
                if let s = score {
                    let cls = s >= 60 ? "pass" : "fail"
                    html += "<td class='\(cls)'>\(Self.formatScore(s))</td>"
                    total += s
                    hasAny = true
                } else {
                    html += "<td class='empty'>—</td>"
                }
            }
            html += "<td class='total'>\(hasAny ? Self.formatScore(total) : "—")</td></tr>"
        }

        html += "</table></body></html>"
        printHTML(title: "\(examName)成绩单", html: html)
    }

    // MARK: - 工具方法
    private static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: Date())
    }

    private static func formatScore(_ score: Double) -> String {
        if score.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(score))
        }
        return String(format: "%.1f", score)
    }
}
