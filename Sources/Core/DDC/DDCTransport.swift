import Foundation
import IOKit

// MARK: - DDC Transport Protocol

protocol DDCTransport {
    func write(command: UInt8, value: UInt16) throws
    func read(command: UInt8) throws -> UInt16
    /// Test if the monitor actually responds to DDC commands
    func probeDDC() -> Bool
}

// MARK: - IOAVService runtime loader

private enum IOAVServiceLoader {
    typealias CreateWithServiceFunc = @convention(c) (CFAllocator?, io_service_t) -> Unmanaged<CFTypeRef>?
    typealias WriteI2CFunc = @convention(c) (CFTypeRef, UInt32, UInt32, UnsafeMutablePointer<UInt8>, UInt32) -> IOReturn
    typealias ReadI2CFunc = @convention(c) (CFTypeRef, UInt32, UInt32, UnsafeMutablePointer<UInt8>, UInt32) -> IOReturn

    private static let handle = dlopen(nil, RTLD_LAZY)

    static let createWithService: CreateWithServiceFunc? = {
        guard let h = handle, let sym = dlsym(h, "IOAVServiceCreateWithService") else { return nil }
        return unsafeBitCast(sym, to: CreateWithServiceFunc.self)
    }()

    static let writeI2C: WriteI2CFunc? = {
        guard let h = handle, let sym = dlsym(h, "IOAVServiceWriteI2C") else { return nil }
        return unsafeBitCast(sym, to: WriteI2CFunc.self)
    }()

    static let readI2C: ReadI2CFunc? = {
        guard let h = handle, let sym = dlsym(h, "IOAVServiceReadI2C") else { return nil }
        return unsafeBitCast(sym, to: ReadI2CFunc.self)
    }()

    static var isAvailable: Bool {
        createWithService != nil && writeI2C != nil && readI2C != nil
    }

    /// Find the External DCPAVServiceProxy and create an IOAVService for it
    static func createExternalService() -> CFTypeRef? {
        guard let createFn = createWithService else { return nil }

        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("DCPAVServiceProxy"),
            &iter
        ) == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iter) }

        var ioService = IOIteratorNext(iter)
        while ioService != 0 {
            defer { IOObjectRelease(ioService); ioService = IOIteratorNext(iter) }

            var props: Unmanaged<CFMutableDictionary>?
            IORegistryEntryCreateCFProperties(ioService, &props, kCFAllocatorDefault, 0)
            let dict = props?.takeRetainedValue() as? [String: Any]
            let location = dict?["Location"] as? String ?? ""

            if location == "External" {
                if let ref = createFn(kCFAllocatorDefault, ioService) {
                    return ref.takeRetainedValue()
                }
            }
        }
        return nil
    }
}

// MARK: - Apple Silicon Transport (targets External display)

final class AppleSiliconDDCTransport: DDCTransport {
    private var cachedService: CFTypeRef?

    private func getService() throws -> CFTypeRef {
        if let s = cachedService { return s }
        guard let s = IOAVServiceLoader.createExternalService() else {
            throw DDCError.serviceUnavailable
        }
        cachedService = s
        return s
    }

    func write(command: UInt8, value: UInt16) throws {
        guard let writeFn = IOAVServiceLoader.writeI2C else {
            throw DDCError.unsupportedPlatform
        }
        let service = try getService()
        var data = buildWritePacket(command: command, value: value)
        let result = writeFn(service, 0x37, 0x51, &data, UInt32(data.count))
        guard result == kIOReturnSuccess else {
            throw DDCError.writeFailed(status: result)
        }
    }

    func read(command: UInt8) throws -> UInt16 {
        guard let writeFn = IOAVServiceLoader.writeI2C,
              let readFn = IOAVServiceLoader.readI2C else {
            throw DDCError.unsupportedPlatform
        }
        let service = try getService()

        var request = buildReadRequest(command: command)
        let writeResult = writeFn(service, 0x37, 0x51, &request, UInt32(request.count))
        guard writeResult == kIOReturnSuccess else {
            throw DDCError.writeFailed(status: writeResult)
        }

        usleep(50_000) // 50ms DDC response wait

        var response = [UInt8](repeating: 0, count: 12)
        let readResult = readFn(service, 0x37, 0x51, &response, UInt32(response.count))
        guard readResult == kIOReturnSuccess else {
            throw DDCError.readFailed(status: readResult)
        }

        // Validate DDC response: byte[2] should be 0x02 (Get VCP Feature Reply)
        guard response[2] == 0x02 else {
            throw DDCError.readFailed(status: -1)
        }

        return parseResponse(response)
    }

    /// Probe DDC support by attempting to read brightness (VCP 0x10)
    func probeDDC() -> Bool {
        do {
            _ = try read(command: 0x10) // brightness
            return true
        } catch {
            return false
        }
    }

    // MARK: - Packet Building

    private func buildWritePacket(command: UInt8, value: UInt16) -> [UInt8] {
        let valueHi = UInt8((value >> 8) & 0xFF)
        let valueLo = UInt8(value & 0xFF)
        var packet: [UInt8] = [0x51, 0x84, 0x03, command, valueHi, valueLo]
        let checksum = packet.reduce(UInt8(0x6E)) { $0 ^ $1 }
        packet.append(checksum)
        return packet
    }

    private func buildReadRequest(command: UInt8) -> [UInt8] {
        var packet: [UInt8] = [0x51, 0x82, 0x01, command]
        let checksum = packet.reduce(UInt8(0x6E)) { $0 ^ $1 }
        packet.append(checksum)
        return packet
    }

    private func parseResponse(_ data: [UInt8]) -> UInt16 {
        guard data.count >= 10 else { return 0 }
        return (UInt16(data[8]) << 8) | UInt16(data[9])
    }
}
