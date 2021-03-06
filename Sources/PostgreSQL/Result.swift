import Foundation

#if os(Linux)
    import CPostgreSQLLinux
#else
    import CPostgreSQLMac
#endif

class Result {
    typealias ResultPointer = OpaquePointer

    private(set) var resultPointer: ResultPointer?
    private let configuration: Database.Configuration

    init(configuration: Database.Configuration, resultPointer: ResultPointer) {
        self.configuration = configuration
        self.resultPointer = resultPointer
    }

    lazy var dictionary: [[String: Node]] = {
        let rowCount = PQntuples(self.resultPointer)
        let columnCount = PQnfields(self.resultPointer)

        guard rowCount > 0 && columnCount > 0 else {
            return []
        }

        var parsedData = [[String: Node]]()

        for row in 0..<rowCount {
            var item = [String: Node]()
            for column in 0..<columnCount {
                let name = String(cString: PQfname(self.resultPointer, Int32(column)))

                if PQgetisnull(self.resultPointer, row, column) == 1 {
                    item[name] = .null
                } else if let value = PQgetvalue(self.resultPointer, row, column) {
                    let type = PQftype(self.resultPointer, column)
                    let length = Int(PQgetlength(self.resultPointer, row, column))
                    item[name] = Node(configuration: self.configuration, oid: type, value: value, length: length)
                } else {
                    item[name] = .null
                }
            }
            parsedData.append(item)
        }

        return parsedData
    }()
}
