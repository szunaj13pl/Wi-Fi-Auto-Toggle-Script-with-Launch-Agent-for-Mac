import Foundation
import CoreAudio

let TARGET_NAME = "LCS_USB_Audio"
let OVERRIDE_FLAG = "/tmp/mic_manual_override"
let SCRIPT_SET_FLAG = "/tmp/mic_script_setting"

func log(_ s: String) {
    let df = ISO8601DateFormatter()
    let line = "[\(df.string(from: Date()))] \(s)\n"
    FileHandle.standardError.write(line.data(using: .utf8)!)
}

func fileExists(_ p: String) -> Bool { FileManager.default.fileExists(atPath: p) }
func touch(_ p: String) { FileManager.default.createFile(atPath: p, contents: nil) }
func rm(_ p: String) { try? FileManager.default.removeItem(atPath: p) }

func getInputDevices() -> [(id: AudioDeviceID, name: String)] {
    var size: UInt32 = 0
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    let sys = AudioObjectID(kAudioObjectSystemObject)
    guard AudioObjectGetPropertyDataSize(sys, &addr, 0, nil, &size) == noErr else { return [] }
    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    var ids = [AudioDeviceID](repeating: 0, count: count)
    guard AudioObjectGetPropertyData(sys, &addr, 0, nil, &size, &ids) == noErr else { return [] }

    var result: [(AudioDeviceID, String)] = []
    for id in ids {
        var streamSize: UInt32 = 0
        var streamAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyDataSize(id, &streamAddr, 0, nil, &streamSize) == noErr else { continue }
        if streamSize == 0 { continue }

        var nameAddr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var name: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<CFString?>.size)
        let st = withUnsafeMutablePointer(to: &name) { ptr -> OSStatus in
            AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, ptr)
        }
        if st == noErr, let cf = name?.takeRetainedValue() {
            result.append((id, cf as String))
        }
    }
    return result
}

func getDefaultInput() -> AudioDeviceID {
    var id: AudioDeviceID = 0
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &id)
    return id
}

func setDefaultInput(_ id: AudioDeviceID) -> Bool {
    var devId = id
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    let st = AudioObjectSetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil,
        UInt32(MemoryLayout<AudioDeviceID>.size), &devId)
    return st == noErr
}

var lcsPresent = false

func findLCS() -> (id: AudioDeviceID, name: String)? {
    return getInputDevices().first { $0.name.contains(TARGET_NAME) }
}

func evaluate() {
    let lcs = findLCS()

    guard let lcs = lcs else {
        if lcsPresent {
            log("LCS disconnected — clearing override")
            rm(OVERRIDE_FLAG)
            lcsPresent = false
        }
        return
    }

    let wasPresent = lcsPresent
    lcsPresent = true
    if !wasPresent {
        log("LCS connected (\(lcs.name))")
        rm(OVERRIDE_FLAG)
    }

    if fileExists(OVERRIDE_FLAG) {
        return
    }

    let current = getDefaultInput()
    if current != lcs.id {
        log("Setting default input → \(lcs.name)")
        touch(SCRIPT_SET_FLAG)
        if !setDefaultInput(lcs.id) {
            log("setDefaultInput failed")
            rm(SCRIPT_SET_FLAG)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                rm(SCRIPT_SET_FLAG)
            }
        }
    }
}

let sysObj = AudioObjectID(kAudioObjectSystemObject)

var devicesAddr = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDevices,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain)

let devicesBlock: AudioObjectPropertyListenerBlock = { _, _ in
    evaluate()
}
AudioObjectAddPropertyListenerBlock(sysObj, &devicesAddr, DispatchQueue.main, devicesBlock)

var defAddr = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultInputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain)

let defBlock: AudioObjectPropertyListenerBlock = { _, _ in
    if fileExists(SCRIPT_SET_FLAG) { return }
    guard let lcs = findLCS() else { return }
    let current = getDefaultInput()
    if current != lcs.id {
        log("Manual change detected — override set")
        touch(OVERRIDE_FLAG)
    } else {
        // user switched back to LCS — clear override
        if fileExists(OVERRIDE_FLAG) {
            log("User switched back to LCS — clearing override")
            rm(OVERRIDE_FLAG)
        }
    }
}
AudioObjectAddPropertyListenerBlock(sysObj, &defAddr, DispatchQueue.main, defBlock)

evaluate()
log("auto-default-mic daemon started")
RunLoop.main.run()
