//
//  fileicon.swift
//  MyAcolyte
//
//  Created by admin17 on 07/03/25.
//

import Foundation
import SwiftUI

struct FileIcon: View {
    let item: FileSystemItem
    let size: CGFloat
    
    var body: some View {
        Group {
            if item.type == .folder {
                Image(systemName: "folder.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(UIColor.systemYellow))
            } else if item.type == .file {
                if item.fileType == .pdf {
                    Image(systemName: "doc.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color(UIColor.systemRed))
                } else if item.fileType == .note {
                    Image(systemName: "note.text")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color(UIColor.systemGreen))
                }
            } else if item.type == .whiteboard { // ✅ Updated to check type instead of fileType
                Image(systemName: "scribble")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(UIColor.systemBlue))
            }
        }
        .frame(width: size, height: size)
    }
}
