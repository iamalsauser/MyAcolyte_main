import Foundation
import SwiftUI
import UserNotifications
import PencilKit

// Additional structures for study tracking
struct StudyProgress: Codable, Identifiable {
    let id: String
    var documentId: String
    var progress: Double // 0.0 to 1.0
    var totalTimeSpent: Int // in minutes
    var lastStudied: Date
    var completedSections: [String]
    
    var percentComplete: Int {
        return Int(progress * 100)
    }
    
    var formattedTimeSpent: String {
        return "\(totalTimeSpent)mins"
    }
    
    var lastStudiedText: String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(lastStudied) {
            return "Today"
        } else if calendar.isDateInYesterday(lastStudied) {
            return "Yesterday"
        } else {
            let dayDiff = calendar.dateComponents([.day], from: lastStudied, to: now).day ?? 0
            return "\(dayDiff)days ago"
        }
    }
}

struct DocumentItem: Identifiable {
    let id: String
    let title: String
}

class FileSystemViewModel: ObservableObject {
    @Published var fileSystem: [FileSystemItem] = []
    @Published var currentFolder: String? = nil
    @Published var currentPath: [String] = []
    @Published var editingItem: String? = nil
    @Published var deleteMode: Bool = false
    @Published var selectionMode: Bool = false
    @Published var selectedItems: Set<String> = []
    @Published var viewMode: ViewMode = .grid
    @Published var sortOrder: SortOrder = .nameAscending
    @Published var showDocumentPicker: Bool = false
    @Published var currentDocument: DocumentItem? = nil
    @Published var recentFiles: [FileSystemItem] = []
    @Published var studyProgress: [StudyProgress] = []
    @Published var recentsUpdated: Bool = false
    
    private let maxRecentFiles = 5
    
    let storageService = FileSystemStorageService()
    
    enum ViewMode {
        case grid
        case list
    }
    
    enum SortOrder: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case dateCreatedNewest = "Newest First"
        case dateCreatedOldest = "Oldest First"
        case dateModifiedNewest = "Recently Modified"
        case dateModifiedOldest = "Least Recently Modified"
    }
    
    init() {
        loadFileSystem()
        loadStudyProgress()
        
        // Add sample data if needed
        if fileSystem.isEmpty {
            addSampleData()
        }
    }
    
    // MARK: - File System Operations
    
    func addToRecentFiles(_ file: FileSystemItem) {
        if let existingIndex = recentFiles.firstIndex(where: { $0.id == file.id }) {
            recentFiles.remove(at: existingIndex)  // Remove duplicate
        }
        recentFiles.insert(file, at: 0)  // Add to top
        if recentFiles.count > maxRecentFiles {
            recentFiles.removeLast()  // Limit recent files list
        }
        recentsUpdated = true
    }
    
    func openFile(_ file: FileSystemItem) {
        addToRecentFiles(file)
        currentDocument = DocumentItem(id: file.id, title: file.name)
        
        // Create or update study progress
        updateStudyProgress(for: file.id)
    }
    
    func loadFileSystem() {
        fileSystem = storageService.loadFileSystem()
        if fileSystem.isEmpty {
            let documentsFolder = FileSystemItem(
                id: UUID().uuidString,
                name: "Documents",
                type: .folder
            )
            fileSystem = [documentsFolder]
            saveFileSystem()
        }
    }
    
    func saveFileSystem() {
        storageService.saveFileSystem(fileSystem)
    }
    
    // MARK: - Study Progress Tracking
    
    func loadStudyProgress() {
        if let data = UserDefaults.standard.data(forKey: "studyProgress") {
            do {
                let decoder = JSONDecoder()
                studyProgress = try decoder.decode([StudyProgress].self, from: data)
            } catch {
                print("Error decoding study progress: \(error)")
                studyProgress = []
            }
        }
    }
    
    func saveStudyProgress() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(studyProgress)
            UserDefaults.standard.set(data, forKey: "studyProgress")
        } catch {
            print("Error encoding study progress: \(error)")
        }
    }
    
    func updateStudyProgress(for documentId: String, incrementTimeBy minutes: Int = 1) {
        if let index = studyProgress.firstIndex(where: { $0.documentId == documentId }) {
            // Update existing
            studyProgress[index].lastStudied = Date()
            studyProgress[index].totalTimeSpent += minutes
            
            // Simulate progress increase
            let newProgress = min(1.0, studyProgress[index].progress + Double(minutes) / 100)
            studyProgress[index].progress = newProgress
        } else {
            // Create new
            let newProgress = StudyProgress(
                id: UUID().uuidString,
                documentId: documentId,
                progress: 0.1,
                totalTimeSpent: minutes,
                lastStudied: Date(),
                completedSections: []
            )
            studyProgress.append(newProgress)
        }
        
        saveStudyProgress()
    }
    
    func getStudyProgress(for documentId: String) -> StudyProgress? {
        return studyProgress.first(where: { $0.documentId == documentId })
    }
    
    func getRecentStudyItems(limit: Int = 3) -> [(FileSystemItem, StudyProgress)] {
        var result: [(FileSystemItem, StudyProgress)] = []
        
        // Sort progress by most recent first
        let sortedProgress = studyProgress.sorted(by: { $0.lastStudied > $1.lastStudied })
        
        for progress in sortedProgress.prefix(limit) {
            if let file = fileSystem.first(where: { $0.id == progress.documentId }) {
                result.append((file, progress))
            }
        }
        
        return result
    }
    
    // MARK: - User Actions
    
    func createFolder() {
        let newFolder = FileSystemItem(
            id: UUID().uuidString,
            name: "New Folder",
            type: .folder,
            fileType: nil,
            parentId: currentFolder
        )
        
        fileSystem.append(newFolder)
        saveFileSystem()
        editingItem = newFolder.id
        NotificationManager.shared.sendNotification(title: "Folder Created", message: "Your new folder '\(newFolder.name)' is ready.")
    }
    
    func deleteItems() {
        if selectionMode && !selectedItems.isEmpty {
            fileSystem.removeAll { selectedItems.contains($0.id) }
            selectedItems.removeAll()
        } else if let itemToDelete = editingItem {
            fileSystem.removeAll { $0.id == itemToDelete }
            editingItem = nil
        }
        
        saveFileSystem()
        selectionMode = false
    }
    
    func renameItem(id: String, newName: String) {
        if newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            editingItem = nil
            return
        }
        
        for i in 0..<fileSystem.count {
            if fileSystem[i].id == id {
                if fileSystem[i].type == .file {
                    let fileExtension = fileSystem[i].fileType == .pdf ? ".pdf" : ".notes"
                    fileSystem[i].name = newName.hasSuffix(fileExtension) ?
                    newName.trimmingCharacters(in: .whitespacesAndNewlines) :
                    "\(newName.trimmingCharacters(in: .whitespacesAndNewlines))\(fileExtension)"
                } else if fileSystem[i].type == .whiteboard {
                    let fileExtension = ".whiteboard"
                    fileSystem[i].name = newName.hasSuffix(fileExtension) ?
                    newName.trimmingCharacters(in: .whitespacesAndNewlines) :
                    "\(newName.trimmingCharacters(in: .whitespacesAndNewlines))\(fileExtension)"
                } else {
                    fileSystem[i].name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                fileSystem[i].dateModified = Date()
                break
            }
        }
        
        saveFileSystem()
        editingItem = nil
    }
    
    func navigateToFolder(item: FileSystemItem) {
        currentFolder = item.id
        
        var path = [item.name]
        var parentId = item.parentId
        
        while parentId != nil {
            if let parent = fileSystem.first(where: { $0.id == parentId }) {
                path.insert(parent.name, at: 0)
                parentId = parent.parentId
            } else {
                break
            }
        }
        
        currentPath = path
    }
    
    func navigateBack() {
        if let currentFolderId = currentFolder,
           let folder = fileSystem.first(where: { $0.id == currentFolderId }),
           let parentId = folder.parentId {
            if let parentFolder = fileSystem.first(where: { $0.id == parentId }) {
                navigateToFolder(item: parentFolder)
            } else {
                currentFolder = nil
                currentPath = []
            }
        } else {
            currentFolder = nil
            currentPath = []
        }
    }
    
    func navigateToRoot() {
        currentFolder = nil
        currentPath = []
    }
    
    func toggleSelection(item: FileSystemItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }
    
    func toggleSelectionMode() {
        selectionMode.toggle()
        if !selectionMode {
            selectedItems.removeAll()
        }
    }
    
    func toggleViewMode() {
        viewMode = viewMode == .grid ? .list : .grid
    }
    
    func changeSortOrder(_ order: SortOrder) {
        sortOrder = order
    }
    
    func importPDF(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let documentId = UUID().uuidString
            
            var fileName = url.lastPathComponent
            if !fileName.hasSuffix(".pdf") {
                fileName += ".pdf"
            }
            
            storageService.savePdf(id: documentId, pdfData: data)
            
            let newFile = FileSystemItem(
                id: documentId,
                name: fileName,
                type: .file,
                fileType: .pdf,
                parentId: currentFolder
            )
            
            fileSystem.append(newFile)
            saveFileSystem()
            
            // Add to recent files
            addToRecentFiles(newFile)
            
            // Create initial study progress
            updateStudyProgress(for: documentId)
            
            currentDocument = DocumentItem(id: documentId, title: fileName)
            
            NotificationManager.shared.sendNotification(title: "Import Successful", message: "Your PDF has been imported.")
        } catch {
            print("Error importing PDF: \(error)")
        }
    }
    
    func createNewNote() {
        let documentId = UUID().uuidString
        let fileName = "New Note.notes"
        
        storageService.saveNote(id: documentId, content: "")
        
        let newFile = FileSystemItem(
            id: documentId,
            name: fileName,
            type: .file,
            fileType: .note,
            parentId: currentFolder
        )
        
        fileSystem.append(newFile)
        saveFileSystem()
        
        currentDocument = DocumentItem(id: documentId, title: fileName)
        editingItem = documentId
    }
    
    func createNewWhiteboard() {
        let documentId = UUID().uuidString
        let fileName = "New Whiteboard.whiteboard"
        
        let emptyDrawing = PKDrawing()
        storageService.saveWhiteboard(id: documentId, drawing: emptyDrawing)
        
        let newFile = FileSystemItem(
            id: documentId,
            name: fileName,
            type: .whiteboard,
            fileType: nil,
            parentId: currentFolder
        )
        
        fileSystem.append(newFile)
        saveFileSystem()
        
        currentDocument = DocumentItem(id: documentId, title: fileName)
        NotificationManager.shared.sendNotification(title: "Whiteboard Created", message: "Your new whiteboard '\(fileName)' is ready.")
    }
    
    // MARK: - Helper Methods
    
    func getCurrentItems() -> [FileSystemItem] {
        var items: [FileSystemItem]
        
        if currentFolder == nil {
            items = fileSystem.filter { $0.parentId == nil }
        } else {
            items = fileSystem.filter { item in
                item.parentId == currentFolder
            }
        }
        
        return sortItems(items)
    }
    
    private func sortItems(_ items: [FileSystemItem]) -> [FileSystemItem] {
        switch sortOrder {
        case .nameAscending:
            return items.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDescending:
            return items.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .dateCreatedNewest:
            return items.sorted { $0.dateCreated > $1.dateCreated }
        case .dateCreatedOldest:
            return items.sorted { $0.dateCreated < $1.dateCreated }
        case .dateModifiedNewest:
            return items.sorted { $0.dateModified > $1.dateModified }
        case .dateModifiedOldest:
            return items.sorted { $0.dateModified < $1.dateModified }
        }
    }
    
    func getPdfById(id: String) -> URL? {
        return storageService.getPdfById(id: id)
    }
    
    func getNoteById(id: String) -> String? {
        return storageService.getNoteById(id: id)
    }
    
    func getWhiteboardById(id: String) -> PKDrawing? {
        return storageService.getWhiteboardById(id: id)
    }
    
    // MARK: - Sample Data
    
    func addSampleData() {
        // Add some sample folders and files for anatomy studies
        let anatomyFolder = FileSystemItem(
            id: UUID().uuidString,
            name: "Anatomy",
            type: .folder
        )
        
        let physiologyFolder = FileSystemItem(
            id: UUID().uuidString,
            name: "Physiology",
            type: .folder
        )
        
        fileSystem.append(anatomyFolder)
        fileSystem.append(physiologyFolder)
        
        // Add sample PDFs
        let pdfNames = [
            "Unit 1 - Introduction to Anatomy",
            "Unit 2 - Cell Structure",
            "Unit 3 - Tissues",
            "Unit 4 - Skin and Membranes",
            "Unit 5 - Skeletal System",
            "Unit 6 - Muscular System",
            "Unit 7 - Nervous System",
            "Unit 8 - Special Senses",
            "Unit 9 - Anatomy"
        ]
        
        for name in pdfNames {
            let documentId = UUID().uuidString
            let fileName = "\(name).pdf"
            
            let newFile = FileSystemItem(
                id: documentId,
                name: fileName,
                type: .file,
                fileType: .pdf,
                parentId: anatomyFolder.id
            )
            
            fileSystem.append(newFile)
            
            // Create study progress for each
            let progress = StudyProgress(
                id: UUID().uuidString,
                documentId: documentId,
                progress: Double.random(in: 0.1...0.9),
                totalTimeSpent: Int.random(in: 5...60),
                lastStudied: Date().addingTimeInterval(-Double.random(in: 0...86400*7)),
                completedSections: []
            )
            
            studyProgress.append(progress)
            
            // Add some to recent files
            if name == "Unit 9 - Anatomy" || name == "Unit 8 - Special Senses" || name == "Unit 7 - Nervous System" {
                addToRecentFiles(newFile)
            }
        }
        
        // Add sample notes
        let noteNames = [
            "Anatomy Lecture Notes",
            "Physiology Study Summary",
            "Medical Terminology",
            "Clinical Case Studies"
        ]
        
        for name in noteNames {
            let documentId = UUID().uuidString
            let fileName = "\(name).notes"
            
            let content = "# \(name)\n\nThese are sample study notes for the medical curriculum.\n\n## Key Points\n\n- Important concept 1\n- Important concept 2\n- Important concept 3\n\n## References\n\n1. Textbook A\n2. Textbook B\n3. Online resource C"
            
            storageService.saveNote(id: documentId, content: content)
            
            let newFile = FileSystemItem(
                id: documentId,
                name: fileName,
                type: .file,
                fileType: .note,
                parentId: nil
            )
            
            fileSystem.append(newFile)
            
            // Add some to recent files
            if name == "Anatomy Lecture Notes" {
                addToRecentFiles(newFile)
            }
        }
        
        // Add sample whiteboards
        let whiteboardNames = [
            "Anatomy Diagram",
            "Physiology Flowchart",
            "Brain Structure"
        ]
        
        for name in whiteboardNames {
            let documentId = UUID().uuidString
            let fileName = "\(name).whiteboard"
            
            let emptyDrawing = PKDrawing()
            storageService.saveWhiteboard(id: documentId, drawing: emptyDrawing)
            
            let newFile = FileSystemItem(
                id: documentId,
                name: fileName,
                type: .whiteboard,
                fileType: nil,
                parentId: nil
            )
            
            fileSystem.append(newFile)
        }
        
        saveFileSystem()
        saveStudyProgress()
    }
}
