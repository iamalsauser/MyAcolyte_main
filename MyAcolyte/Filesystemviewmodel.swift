//
//  Filesystemviewmodel.swift
//  MyAcolyte
//
//  Created by admin17 on 07/03/25.
//

import Foundation
import SwiftUI

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
//    @Published var currentDocument: (id: String, title: String)? = nil
    @Published var currentDocument: DocumentItem? = nil

    
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
    }
    
    // MARK: - File System Operations
    func loadFileSystem() {
        fileSystem = storageService.loadFileSystem()
        if fileSystem.isEmpty {
            // Create a default Documents folder if the file system is empty
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
        
        // Build the path
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
            // Navigate to parent folder
            if let parentFolder = fileSystem.first(where: { $0.id == parentId }) {
                navigateToFolder(item: parentFolder)
            } else {
                // If parent not found, go to root
                currentFolder = nil
                currentPath = []
            }
        } else {
            // Already at root
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
            
            // Get the filename from the URL
            var fileName = url.lastPathComponent
            if !fileName.hasSuffix(".pdf") {
                fileName += ".pdf"
            }
            
            // Save the PDF data
            storageService.savePdf(id: documentId, pdfData: data)
            
            // Create file system entry
            let newFile = FileSystemItem(
                id: documentId,
                name: fileName,
                type: .file,
                fileType: .pdf,
                parentId: currentFolder
            )
            
            fileSystem.append(newFile)
            saveFileSystem()
            
            // Set as current document
            currentDocument = DocumentItem(id: documentId, title: fileName)
        } catch {
            print("Error importing PDF: \(error)")
        }
    }
    
    func createNewNote() {
        let documentId = UUID().uuidString
        let fileName = "New Note.notes"
        
        // Save empty note
        storageService.saveNote(id: documentId, content: "")
        
        // Create file system entry
        let newFile = FileSystemItem(
            id: documentId,
            name: fileName,
            type: .file,
            fileType: .note,
            parentId: currentFolder
        )
        
        fileSystem.append(newFile)
        saveFileSystem()
        
        // Set as current document and start editing
        currentDocument = DocumentItem(id: documentId, title: fileName)
        editingItem = documentId
    }
    
    // MARK: - Helper Methods
    func getCurrentItems() -> [FileSystemItem] {
        var items: [FileSystemItem]
        
        if currentFolder == nil {
            // Top-level items
            items = fileSystem.filter { $0.parentId == nil }
        } else {
            // Items inside current folder
            items = fileSystem.filter { item in
                item.parentId == currentFolder
            }
        }
        
        // Sort items
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
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Error: Documents directory not found!")
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent("\(id).pdf")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("✅ PDF found at: \(fileURL.absoluteString)")
            return fileURL
        } else {
            print("❌ PDF file not found for id: \(id)")
            return nil
        }
    }

    
    func getNoteById(id: String) -> String? {
        return storageService.getNoteById(id: id)
    }
}
