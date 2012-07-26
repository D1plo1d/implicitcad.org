// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you
// may not use this file except in compliance with the License. You
// may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied. See the License for the specific language governing
// permissions and limitations under the License.
#ifndef WEBGL_LOADER_BASE_H_
#define WEBGL_LOADER_BASE_H_

#include <stdio.h>
#include <stdlib.h>

#include <vector>

typedef unsigned short uint16;
typedef short int16;

typedef std::vector<float> AttribList;
typedef std::vector<int> IndexList;
typedef std::vector<uint16> QuantizedAttribList;
typedef std::vector<uint16> OptimizedIndexList;

// TODO: these data structures ought to go elsewhere.
struct DrawMesh {
  // Interleaved vertex format:
  //  3-D Position
  //  3-D Normal
  //  2-D TexCoord
  // Note that these
  AttribList attribs;
  // Indices are 0-indexed.
  IndexList indices;
};

struct WebGLMesh {
  QuantizedAttribList attribs;
  OptimizedIndexList indices;
};

typedef std::vector<WebGLMesh> WebGLMeshList;

static inline int strtoint(const char* str, const char** endptr) {
  return static_cast<int>(strtol(str, const_cast<char**>(endptr), 10));
}

// TODO: Visual Studio calls this someting different.
#ifdef putc_unlocked
# define PutChar putc_unlocked
#else
# define PutChar putc
#endif  // putc_unlocked

#ifndef CHECK
# define CHECK(PRED) if (!(PRED)) {                                     \
    fprintf(stderr, "%s:%d CHECK failed: " #PRED "\n", __FILE__, __LINE__); \
    exit(-1); } else
#endif  // CHECK

#endif  // WEBGL_LOADER_BASE_H_
