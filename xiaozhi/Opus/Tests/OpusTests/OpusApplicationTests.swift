import AVFoundation
import Opus
import XCTest

final class OpusApplicationTests: XCTestCase {
	func testInitializer() {
		_ = OpusCodec.Application(Int(0))
		_ = OpusCodec.Application(UInt8(0))
		_ = OpusCodec.Application(UInt16(0))
		_ = OpusCodec.Application(UInt32(0))
		_ = OpusCodec.Application(UInt64(0))
		_ = OpusCodec.Application(Int8(0))
		_ = OpusCodec.Application(Int16(0))
		_ = OpusCodec.Application(Int32(0))
		_ = OpusCodec.Application(Int64(0))
	}

	func testValues() {
		XCTAssertEqual(OpusCodec.Application.audio.rawValue, OPUS_APPLICATION_AUDIO)
		XCTAssertEqual(OpusCodec.Application.voip.rawValue, OPUS_APPLICATION_VOIP)
		XCTAssertEqual(OpusCodec.Application.restrictedLowDelay.rawValue, OPUS_APPLICATION_RESTRICTED_LOWDELAY)
	}
}
