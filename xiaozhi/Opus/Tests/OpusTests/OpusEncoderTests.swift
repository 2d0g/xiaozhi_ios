import AVFoundation
import XCTest

@testable import Opus

final class OpusEncoderTests: XCTestCase {
	func testInit() throws {
		try AVAudioFormatTests.validFormats.forEach {
			_ = try OpusCodec.Encoder(format: $0)
		}

		try AVAudioFormatTests.invalidFormats.forEach {
			XCTAssertThrowsError(try OpusCodec.Encoder(format: $0)) { error in
				XCTAssertEqual(error as! OpusCodec.Error, OpusCodec.Error.badArgument)
			}
		}
	}
}
