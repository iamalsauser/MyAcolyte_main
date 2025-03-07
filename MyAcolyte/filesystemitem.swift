import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Models
struct FileSystemItem: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var type: FileType
    var fileType: FileContentType?
    var parentId: String?
    var dateCreated: Date
    var dateModified: Date
    
    enum FileType: String, Codable {
        case file
        case folder
    }
    
    enum FileContentType: String, Codable {
        case pdf
        case note
    }
    
    static func == (lhs: FileSystemItem, rhs: FileSystemItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String, name: String, type: FileType, fileType: FileContentType? = nil, parentId: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.fileType = fileType
        self.parentId = parentId
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

// MARK: - File System Storage Service
class FileSystemStorageService {
    private let fileSystemKey = "fileSystem"
    
    func saveFileSystem(_ fileSystem: [FileSystemItem]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(fileSystem)
            UserDefaults.standard.set(data, forKey: fileSystemKey)
        } catch {
            print("Error encoding file system: \(error)")
        }
    }
    
    func loadFileSystem() -> [FileSystemItem] {
        if let data = UserDefaults.standard.data(forKey: fileSystemKey) {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode([FileSystemItem].self, from: data)
            } catch {
                print("Error decoding file system: \(error)")
                return []
            }
        }
        return []
    }
    
    // MARK: - Document Storage
    
    // Save PDF document
    func savePdf(id: String, pdfData: Data) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(id).pdf")
        
        do {
            try pdfData.write(to: fileURL)
            print("PDF saved successfully at: \(fileURL)")
        } catch {
            print("Error saving PDF: \(error)")
        }
    }
    
    // Get PDF document
    func getPdfById(id: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(id).pdf")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        } else {
            print("PDF file not found for id: \(id)")
            return nil
        }
    }
    
    // Save Note
    func saveNote(id: String, content: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(id).notes")
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Note saved successfully at: \(fileURL)")
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    // Get Note
    func getNoteById(id: String) -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(id).notes")
        
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            print("Error loading note: \(error)")
            return nil
        }
    }
}

// MARK: - ViewModel


// MARK: - File Icons


// MARK: - File Item Grid View


// MARK: - File Item List View


// MARK: - Path View


// MARK: - Toolbar Items


// MARK: - PDF Viewer

// MARK: - Document Picker


// MARK: - Note Editor View


// MARK: - PDF Viewer View


// MARK: - Main File System View

