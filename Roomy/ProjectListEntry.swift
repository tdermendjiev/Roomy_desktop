//
//  ProjectListEntry.swift
//  Roomy
//
//  How the user arrived at the project list (S04); drives future pre-selection / filters.
//

import Foundation

enum ProjectListEntry: Equatable {
    case reviewAll
    case dormantPreSelected
    case deleteDormantOnly
}
