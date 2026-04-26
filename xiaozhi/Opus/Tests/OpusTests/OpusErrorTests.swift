import AVFoundation
import Opus
import XCTest

final class OpusErrorTests: XCTestCase {
	func testInitializer() {
		_ = OpusCodec.Error(Int(0))
		_ = OpusCodec.Error(UInt8(0))
		_ = OpusCodec.Error(UInt16(0))
		_ = OpusCodec.Error(UInt32(0))
		_ = OpusCodec.Error(UInt64(0))
		_ = OpusCodec.Error(Int8(0))
		_ = OpusCodec.Error(Int16(0))
		_ = OpusCodec.Error(Int32(0))
		_ = OpusCodec.Error(Int64(0))
	}

	func testValues() {
		XCTAssertEqual(OpusCodec.Error.ok.rawValue, OPUS_OK)
		XCTAssertEqual(OpusCodec.Error.badArgument.rawValue, OPUS_BAD_ARG)
		XCTAssertEqual(OpusCodec.Error.bufferTooSmall.rawValue, OPUS_BUFFER_TOO_SMALL)
		XCTAssertEqual(OpusCodec.Error.internalError.rawValue, OPUS_INTERNAL_ERROR)
		XCTAssertEqual(OpusCodec.Error.invalidPacket.rawValue, OPUS_INVALID_PACKET)
		XCTAssertEqual(OpusCodec.Error.unimplemented.rawValue, OPUS_UNIMPLEMENTED)
		XCTAssertEqual(OpusCodec.Error.invalidState.rawValue, OPUS_INVALID_STATE)
		XCTAssertEqual(OpusCodec.Error.allocationFailure.rawValue, OPUS_ALLOC_FAIL)
	}
}
