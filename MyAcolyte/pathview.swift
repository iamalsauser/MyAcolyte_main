//
//  pathview.swift
//  MyAcolyte
//
//  Created by admin17 on 07/03/25.
//

import Foundation
import SwiftUI

struct PathView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    viewModel.navigateToRoot()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .foregroundColor(.primary)
                }
                
                ForEach(0..<viewModel.currentPath.count, id: \.self) { index in
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        // Navigate to this part of the path
                        // This would require additional logic to find the folder
                    }) {
                        Text(viewModel.currentPath[index])
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
        .background(Color(UIColor.secondarySystemBackground))
    }
}
