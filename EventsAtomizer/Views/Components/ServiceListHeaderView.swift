//
//  ServiceListHeaderView.swift
//  EventsAtomizer
//
//  Created by localadmin on 18/02/2025.
//

import SwiftUI


struct ServiceListHeaderView: View {
    @Binding var sortType: ServiceSortType
    @Binding var sortAscending: Bool
    
    var body: some View {
        HStack {
            ForEach(ServiceSortType.allCases, id: \.self) { type in
                Button {
                    if sortType == type {
                        sortAscending.toggle()
                    } else {
                        sortType = type
                        sortAscending = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: type.image)
                        Text(type.rawValue)
                        if sortType == type {
                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        }
                    }
                }
                .buttonStyle(.borderless)
                
                if type != .eventName {
                    Divider()
                        .frame(height: 20)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
    }
}
