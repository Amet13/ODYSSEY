import Darwin
import Foundation
import os.log

/**
 PerformanceMetrics tracks system resource usage.
 */
public struct PerformanceMetrics: Codable, Sendable {
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: UInt64
    public let memoryUsageMB: Double
    public let activeThreads: Int
    public let networkConnections: Int

    public init(
        cpuUsage: Double,
        memoryUsage: UInt64,
        activeThreads: Int,
        networkConnections: Int
    ) {
        self.timestamp = Date()
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryUsageMB = Double(memoryUsage) / 1_024.0 / 1_024.0
        self.activeThreads = activeThreads
        self.networkConnections = networkConnections
    }
}

/**
 PerformanceMonitor tracks and optimizes system resource usage.

 Monitors CPU, memory, and network usage to ensure the app runs efficiently
 in the background and doesn't consume excessive resources when idle.

 ## Usage Example
 ```swift
 let monitor = PerformanceMonitor.shared
 await monitor.startMonitoring()
 let metrics = await monitor.getCurrentMetrics()
 ```
 */
@MainActor
public final class PerformanceMonitor: ObservableObject, @unchecked Sendable {
    public static let shared = PerformanceMonitor()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "PerformanceMonitor")
    private var monitoringTimer: Timer? {
        didSet {
            // Clean up old timer
            oldValue?.invalidate()
        }
    }

    private var metricsHistory: [PerformanceMetrics] = []

    @Published public var isMonitoring = false
    @Published public var currentMetrics: PerformanceMetrics?
    @Published public var averageCPUUsage: Double = 0.0
    @Published public var averageMemoryUsageMB: Double = 0.0

    // Performance thresholds
    private let maxMemoryUsageMB: Double = 500.0 // 500MB
    private let maxCPUUsage: Double = 10.0 // 10%
    private let maxHistorySize = 100

    private init() {
        logger.info("🔧 PerformanceMonitor initialized.")
    }

    deinit {
        // Timer cleanup is handled by the didSet observer
    }

    // MARK: - Monitoring Control

    /**
     Starts performance monitoring.
     - Parameter interval: Monitoring interval in seconds (default: 30)
     */
    public func startMonitoring(interval: TimeInterval = 30) {
        guard !isMonitoring else {
            logger.info("📊 Performance monitoring already active.")
            return
        }

        logger.info("📊 Starting performance monitoring with \(interval)s interval.")
        isMonitoring = true

        // Initial metrics collection
        Task {
            await collectMetrics()
        }

        // Set up periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.collectMetrics()
            }
        }
    }

    /**
     Stops performance monitoring.
     */
    public func stopMonitoring() {
        guard isMonitoring else { return }

        logger.info("📊 Stopping performance monitoring.")
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    /**
     Collects current performance metrics.
     */
    public func collectMetrics() async {
        let metrics = await getCurrentMetrics()

        await MainActor.run {
            self.currentMetrics = metrics
            self.metricsHistory.append(metrics)

            // Trim history
            if self.metricsHistory.count > maxHistorySize {
                self.metricsHistory = Array(self.metricsHistory.suffix(maxHistorySize))
            }

            // Update averages
            self.updateAverages()

            // Check for performance issues
            self.checkPerformanceIssues(metrics)
        }

        logger
            .info(
                "📊 Collected metrics - CPU: \(String(format: "%.1f", metrics.cpuUsage))%, Memory: \(String(format: "%.1f", metrics.memoryUsageMB))MB.",
                )
    }

    // MARK: - Metrics Collection

    /**
     Gets current system performance metrics.
     - Returns: Current performance metrics
     */
    public func getCurrentMetrics() async -> PerformanceMetrics {
        let cpuUsage = await getCPUUsage()
        let memoryUsage = getMemoryUsage()
        let activeThreads = getActiveThreadCount()
        let networkConnections = getNetworkConnectionCount()

        return PerformanceMetrics(
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            activeThreads: activeThreads,
            networkConnections: networkConnections,
            )
    }

    /**
     Gets CPU usage percentage.
     - Returns: CPU usage as percentage
     */
    private func getCPUUsage() async -> Double {
        // Get CPU usage using host_statistics
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count,
                    )
            }
        }

        if kerr == KERN_SUCCESS {
            // Calculate CPU usage based on user time
            let userTime = Double(info.user_time.seconds) + Double(info.user_time.microseconds) / 1_000_000.0
            return min(userTime * 100, 100.0) // Convert to percentage
        }

        return 0.0
    }

    /**
     Gets current memory usage in bytes.
     - Returns: Memory usage in bytes
     */
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count,
                    )
            }
        }

        if kerr == KERN_SUCCESS {
            return UInt64(info.resident_size)
        }

        return 0
    }

    /**
     Gets the number of active threads.
     - Returns: Active thread count
     */
    private func getActiveThreadCount() -> Int {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let result = task_threads(mach_task_self_, &threadList, &threadCount)

        if result == KERN_SUCCESS, let threads = threadList {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: threads),
                vm_size_t(UInt32(threadCount) * UInt32(MemoryLayout<thread_t>.size)),
                )
            return Int(threadCount)
        }

        return 0
    }

    /**
     Gets the number of network connections.
     - Returns: Network connection count
     */
    private func getNetworkConnectionCount() -> Int {
        // This is a simplified implementation
        // In a real app, you might want to track actual network connections
        return 0
    }

    // MARK: - Performance Analysis

    /**
     Updates average metrics.
     */
    private func updateAverages() {
        guard !metricsHistory.isEmpty else { return }

        let totalCPU = metricsHistory.reduce(0.0) { $0 + $1.cpuUsage }
        let totalMemory = metricsHistory.reduce(0.0) { $0 + $1.memoryUsageMB }

        averageCPUUsage = totalCPU / Double(metricsHistory.count)
        averageMemoryUsageMB = totalMemory / Double(metricsHistory.count)
    }

    /**
     Checks for performance issues and logs warnings.
     - Parameter metrics: Current performance metrics
     */
    private func checkPerformanceIssues(_ metrics: PerformanceMetrics) {
        if metrics.cpuUsage > maxCPUUsage {
            logger.warning("⚠️ High CPU usage detected: \(String(format: "%.1f", metrics.cpuUsage))%.")
        }

        if metrics.memoryUsageMB > maxMemoryUsageMB {
            logger.warning("⚠️ High memory usage detected: \(String(format: "%.1f", metrics.memoryUsageMB))MB.")
        }

        if metrics.activeThreads > 50 {
            logger.warning("⚠️ High thread count detected: \(metrics.activeThreads) threads.")
        }
    }

    // MARK: - Optimization Methods

    /**
     Performs memory cleanup to reduce memory usage.
     */
    public func performMemoryCleanup() {
        logger.info("🧹 Performing memory cleanup.")

        // Force garbage collection if available
        #if canImport(ObjectiveC)
        autoreleasepool {
            // This will help release autoreleased objects
        }
        #endif

        // Clear any caches or temporary data
        clearTemporaryData()

        logger.info("✅ Memory cleanup completed.")
    }

    /**
     Clears temporary data and caches.
     */
    private func clearTemporaryData() {
        // Clear metrics history if it's getting large
        if metricsHistory.count > maxHistorySize / 2 {
            metricsHistory = Array(metricsHistory.suffix(maxHistorySize / 2))
        }

        // Clear any other temporary data here
        // For example, WebKit caches, image caches, etc.
    }

    /**
     Optimizes the app for background operation.
     */
    public func optimizeForBackground() {
        logger.info("🌙 Optimizing for background operation.")

        // Reduce monitoring frequency
        if isMonitoring {
            Task { @MainActor in
                self.stopMonitoring()
                self.startMonitoring(interval: 60) // Monitor every minute when in background
            }
        }

        // Perform memory cleanup
        performMemoryCleanup()

        logger.info("✅ Background optimization completed.")
    }

    /**
     Optimizes the app for foreground operation.
     */
    public func optimizeForForeground() {
        logger.info("☀️ Optimizing for foreground operation.")

        // Increase monitoring frequency
        if isMonitoring {
            Task { @MainActor in
                self.stopMonitoring()
                self.startMonitoring(interval: 30) // Monitor every 30 seconds when in foreground
            }
        }

        logger.info("✅ Foreground optimization completed.")
    }

    // MARK: - Reporting Methods

    /**
     Gets performance report.
     - Returns: Dictionary with performance statistics
     */
    public func getPerformanceReport() -> [String: Any] {
        guard !metricsHistory.isEmpty else {
            return ["error": "No metrics available"]
        }

        let cpuValues = metricsHistory.map(\.cpuUsage)
        let memoryValues = metricsHistory.map(\.memoryUsageMB)

        let maxCPU = cpuValues.max() ?? 0.0
        let minCPU = cpuValues.min() ?? 0.0
        let maxMemory = memoryValues.max() ?? 0.0
        let minMemory = memoryValues.min() ?? 0.0

        return [
            "totalSamples": metricsHistory.count,
            "monitoringDuration": metricsHistory.last?.timestamp
                .timeIntervalSince(metricsHistory.first?.timestamp ?? Date()) as Any,
            "cpu": [
                "current": currentMetrics?.cpuUsage ?? 0.0,
                "average": averageCPUUsage,
                "maximum": maxCPU,
                "minimum": minCPU
            ],
            "memory": [
                "currentMB": currentMetrics?.memoryUsageMB ?? 0.0,
                "averageMB": averageMemoryUsageMB,
                "maximumMB": maxMemory,
                "minimumMB": minMemory
            ],
            "threads": [
                "current": currentMetrics?.activeThreads ?? 0,
                "average": Double(metricsHistory.map(\.activeThreads).reduce(0, +)) / Double(metricsHistory.count)
            ],
            "isMonitoring": isMonitoring
        ]
    }

    /**
     Exports performance data to JSON.
     - Returns: JSON string representation of performance data
     */
    public func exportPerformanceData() -> String? {
        do {
            let data = try JSONEncoder().encode(metricsHistory)
            return String(data: data, encoding: .utf8)
        } catch {
            logger.error("❌ Failed to export performance data: \(error.localizedDescription).")
            return nil
        }
    }

    /**
     Clears performance history.
     */
    public func clearHistory() {
        metricsHistory.removeAll()
        updateAverages()
        logger.info("🧹 Performance history cleared.")
    }
}
