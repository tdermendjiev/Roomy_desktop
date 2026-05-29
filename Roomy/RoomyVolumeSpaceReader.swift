//
//  RoomyVolumeSpaceReader.swift
//  Roomy
//
//  Reads volume total / available space for disk charts (S06–S08).
//

import Foundation

enum RoomyVolumeSpaceReader {
    /// Decimal GiB (1024³) for consistency with byte→GB math elsewhere in Roomy.
    static func chartGigabytes(forDirectory directory: URL) -> (used: Double, total: Double)? {
        let url = directory.standardizedFileURL
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
        ]
        guard let vals = try? url.resourceValues(forKeys: keys),
              let totalBytes = vals.volumeTotalCapacity,
              totalBytes > 0 else {
            return nil
        }
        let availableLegacy = vals.volumeAvailableCapacity.map { Int64($0) } ?? 0
        let available = vals.volumeAvailableCapacityForImportantUsage ?? availableLegacy
        let total = Int64(totalBytes)
        let usedBytes = max(0, total - available)
        let div = Double(Int64(1) << 30)
        return (Double(usedBytes) / div, Double(total) / div)
    }

    /// When volume queries fail (permissions, network volume, etc.).
    static let fallbackChartGigabytes: (used: Double, total: Double) = (312, 500)
}
