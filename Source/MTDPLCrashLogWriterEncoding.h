/*
 * Copyright 2008, Dave Benson.
 * Copyright 2008 - 2009 Plausible Labs Cooperative, Inc.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with
 * the License. You may obtain a copy of the License
 * at http://www.apache.org/licenses/LICENSE-2.0 Unless
 * required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#ifndef MTDPLCRASH_LOG_WRITER_ENCODING_H
#define MTDPLCRASH_LOG_WRITER_ENCODING_H

#ifdef __cplusplus
extern "C" {
#endif

#include "MTDPLCrashAsync.h"

typedef enum {
        MTDPLPROTOBUF_C_TYPE_INT32,
        MTDPLPROTOBUF_C_TYPE_SINT32,
        MTDPLPROTOBUF_C_TYPE_SFIXED32,
        MTDPLPROTOBUF_C_TYPE_INT64,
        MTDPLPROTOBUF_C_TYPE_SINT64,
        MTDPLPROTOBUF_C_TYPE_SFIXED64,
        MTDPLPROTOBUF_C_TYPE_UINT32,
        MTDPLPROTOBUF_C_TYPE_FIXED32,
        MTDPLPROTOBUF_C_TYPE_UINT64,
        MTDPLPROTOBUF_C_TYPE_FIXED64,
        MTDPLPROTOBUF_C_TYPE_FLOAT,
        MTDPLPROTOBUF_C_TYPE_DOUBLE,
        MTDPLPROTOBUF_C_TYPE_BOOL,
        MTDPLPROTOBUF_C_TYPE_ENUM,
        MTDPLPROTOBUF_C_TYPE_STRING,
        MTDPLPROTOBUF_C_TYPE_BYTES,
        //MTDPLPROTOBUF_C_TYPE_GROUP,          // NOT SUPPORTED
        MTDPLPROTOBUF_C_TYPE_MESSAGE,
} MTDPLProtobufCType;

typedef struct MTDPLProtobufCBinaryData {
    size_t len;
    void *data;
} MTDPLProtobufCBinaryData;

size_t plcrash_writer_pack (plcrash_async_file_t *file, uint32_t field_id, MTDPLProtobufCType field_type, const void *value);
    
#ifdef __cplusplus
}
#endif

#endif /* MTDPLCRASH_LOG_WRITER_ENCODING_H */
