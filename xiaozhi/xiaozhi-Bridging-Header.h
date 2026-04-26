#ifndef xiaozhi_Bridging_Header_h
#define xiaozhi_Bridging_Header_h

#import "include/c-api.h"
#import <Opus/opus.h>

// 增加辅助函数以绕过 Swift 变参函数限制
static inline void swift_opus_set_bitrate(OpusEncoder *enc, int32_t bitrate) {
    opus_encoder_ctl(enc, OPUS_SET_BITRATE(bitrate));
}

static inline void swift_opus_set_signal(OpusEncoder *enc, int32_t signal) {
    opus_encoder_ctl(enc, OPUS_SET_SIGNAL(signal));
}

static inline void swift_opus_set_complexity(OpusEncoder *enc, int32_t complexity) {
    opus_encoder_ctl(enc, OPUS_SET_COMPLEXITY(complexity));
}

#endif
