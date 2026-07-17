import Foundation

public enum CareerHQCSVError: Error, Equatable { case invalidHeader, malformedRow(Int), invalidStatus(String), invalidArrangement(String) }

public enum CareerHQCSV {
    public static let header = "Employer,Role,Location,Work Arrangement,Status,Date Applied,Follow Up Date,Source URL,Notes,Favorite"

    public static func export(_ applications: [CareerApplication]) -> String {
        let formatter = ISO8601DateFormatter()
        let rows = applications.map { app in
            [app.employer, app.role, app.location, app.workArrangement.rawValue, app.status.rawValue,
             app.dateApplied.map(formatter.string) ?? "", app.followUpDate.map(formatter.string) ?? "",
             app.sourceURL?.absoluteString ?? "", app.notes, app.isFavorite ? "true" : "false"]
                .map(escape).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    public static func importApplications(from csv: String, now: Date = .now) throws -> [CareerApplication] {
        let rows = parse(csv)
        guard rows.first == parse(header).first else { throw CareerHQCSVError.invalidHeader }
        let formatter = ISO8601DateFormatter()
        return try rows.dropFirst().enumerated().compactMap { index, fields in
            guard !fields.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return nil }
            guard fields.count == 10 else { throw CareerHQCSVError.malformedRow(index + 2) }
            guard let arrangement = WorkArrangement(rawValue: fields[3]) else { throw CareerHQCSVError.invalidArrangement(fields[3]) }
            guard let status = ApplicationStatus(rawValue: fields[4]) else { throw CareerHQCSVError.invalidStatus(fields[4]) }
            return CareerApplication(
                employer: fields[0], role: fields[1], location: fields[2], workArrangement: arrangement,
                status: status, dateAdded: now, dateApplied: fields[5].isEmpty ? nil : formatter.date(from: fields[5]),
                lastUpdated: now, followUpDate: fields[6].isEmpty ? nil : formatter.date(from: fields[6]),
                sourceURL: fields[7].isEmpty ? nil : URL(string: fields[7]), notes: fields[8],
                isFavorite: fields[9].lowercased() == "true"
            )
        }
    }

    private static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func parse(_ csv: String) -> [[String]] {
        var rows = [[String]](), row = [String](), field = "", quoted = false
        var index = csv.startIndex
        while index < csv.endIndex {
            let char = csv[index]
            if char == "\"" {
                let next = csv.index(after: index)
                if quoted && next < csv.endIndex && csv[next] == "\"" { field.append("\""); index = next }
                else { quoted.toggle() }
            } else if char == "," && !quoted { row.append(field); field = "" }
            else if (char == "\n" || char == "\r") && !quoted {
                if char == "\r" { let next = csv.index(after: index); if next < csv.endIndex && csv[next] == "\n" { index = next } }
                row.append(field); rows.append(row); row = []; field = ""
            } else { field.append(char) }
            index = csv.index(after: index)
        }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }
}
