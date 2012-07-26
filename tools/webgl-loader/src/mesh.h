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

#ifndef WEBGL_LOADER_MESH_H_
#define WEBGL_LOADER_MESH_H_

#include <float.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <map>
#include <string>
#include <utility>
#include <vector>

#include "base.h"
#include "utf8.h"

void DumpJsonFromQuantizedAttribs(const QuantizedAttribList& attribs) {
  puts("var attribs = new Uint16Array([");
  for (size_t i = 0; i < attribs.size(); i += 8) {
    printf("%u,%hu,%hu,%hu,%hu,%hu,%hu,%hu,\n",
           attribs[i + 0], attribs[i + 1], attribs[i + 2], attribs[i + 3],
           attribs[i + 4], attribs[i + 5], attribs[i + 6], attribs[i + 7]);
  }
  puts("]);");
}

void DumpJsonFromInterleavedAttribs(const AttribList& attribs) {
  puts("var attribs = new Float32Array([");
  for (size_t i = 0; i < attribs.size(); i += 8) {
    printf("%f,%f,%f,%f,%f,%f,%f,%f,\n",
           attribs[i + 0], attribs[i + 1], attribs[i + 2], attribs[i + 3],
           attribs[i + 4], attribs[i + 5], attribs[i + 6], attribs[i + 7]);
  }
  puts("]);");
}

void DumpJsonFromIndices(const IndexList& indices) {
  puts("var indices = new Uint16Array([");
  for (size_t i = 0; i < indices.size(); i += 3) {
    printf("%d,%d,%d,\n", indices[i + 0], indices[i + 1], indices[i + 2]);
  }
  puts("]);");
}

// A short list of floats, useful for parsing a single vector
// attribute.
class ShortFloatList {
 public:
  // MeshLab can create position attributes with
  // color coordinates like: v x y z r g b
  static const size_t kMaxNumFloats = 6;
  ShortFloatList()
      : size_(0)
  {
    clear();
  }

  void clear() {
    for (size_t i = 0; i < kMaxNumFloats; ++i) {
      a_[i] = 0.f;
    }
  }

  // Parse up to kMaxNumFloats from C string.
  // TODO: this should instead return endptr, since size
  // is recoverable.
  size_t ParseLine(const char* line) {
    for (size_ = 0; size_ != kMaxNumFloats; ++size_) {
      char* endptr = NULL;
      a_[size_] = strtof(line, &endptr);
      if (endptr == NULL || line == endptr) break;
      line = endptr;
    }
    return size_;
  }

  void AppendTo(AttribList* attribs) const {
    AppendNTo(attribs, size_);
  }

  void AppendNTo(AttribList* attribs, const size_t sz) const {
    attribs->insert(attribs->end(), a_, a_ + sz);
  }

  bool empty() const { return size_ == 0; }

  size_t size() const { return size_; }
 private:
  float a_[kMaxNumFloats];
  size_t size_;
};

class IndexFlattener {
 public:
  explicit IndexFlattener(size_t num_positions)
      : count_(0),
        table_(num_positions) {
  }

  int count() const { return count_; }

  // Returns a pair of: < flattened index, newly inserted >.
  std::pair<int, bool> GetFlattenedIndex(int position_index,
                                         int texcoord_index,
                                         int normal_index) {
    // First, optimistically look up position_index in the table.
    IndexType& index = table_[position_index];
    if (index.position_or_flat == kIndexUnknown) {
      // This is the first time we've seen this position in the table,
      // so fill it. Since the table is indexed by position, we can
      // use the position_or_flat_index field to store the flat index.
      const int flat_index = count_++;
      index.position_or_flat = flat_index;
      index.texcoord = texcoord_index;
      index.normal = normal_index;
      return std::make_pair(flat_index, true);
    } else if (index.position_or_flat == kIndexNotInTable) {
      // There are multiple flattened indices at this position index,
      // so resort to the map.
      return GetFlattenedIndexFromMap(position_index,
                                      texcoord_index,
                                      normal_index);
    } else if (index.texcoord == texcoord_index &&
               index.normal == normal_index) {
      // The other indices match, so we can use the value cached in
      // the table.
      return std::make_pair(index.position_or_flat, false);
    }
    // The other indices don't match, so we mark this table entry,
    // and insert both the old and new indices into the map.
    const IndexType old_index(position_index, index.texcoord, index.normal);
    map_.insert(std::make_pair(old_index, index.position_or_flat));
    index.position_or_flat = kIndexNotInTable;
    const IndexType new_index(position_index, texcoord_index, normal_index);
    const int flat_index = count_++;
    map_.insert(std::make_pair(new_index, flat_index));
    return std::make_pair(flat_index, true);
  }
 private:
  std::pair<int, bool> GetFlattenedIndexFromMap(int position_index,
                                                int texcoord_index,
                                                int normal_index) {
    IndexType index(position_index, texcoord_index, normal_index);
    MapType::iterator iter = map_.lower_bound(index);
    if (iter == map_.end() || iter->first != index) {
      const int flat_index = count_++;
      map_.insert(iter, std::make_pair(index, flat_index));
      return std::make_pair(flat_index, true);
    } else {
      return std::make_pair(iter->second, false);
    }
  }
  
  static const int kIndexUnknown = -1;
  static const int kIndexNotInTable = -2;
  
  struct IndexType {
    IndexType()
        : position_or_flat(kIndexUnknown),
          texcoord(kIndexUnknown),
          normal(kIndexUnknown)
    { }

    IndexType(int position_index, int texcoord_index, int normal_index)
        : position_or_flat(position_index),
          texcoord(texcoord_index),
          normal(normal_index)
    { }
    
    // I'm being tricky/lazy here. The table_ stores the flattened
    // index in the first field, since it is indexed by position. The
    // map_ stores position and uses this struct as a key to lookup the
    // flattened index.
    int position_or_flat;
    int texcoord;
    int normal;

    // An ordering for std::map.
    bool operator<(const IndexType& that) const {
      if (position_or_flat == that.position_or_flat) {
        if (texcoord == that.texcoord) {
          return normal < that.normal;
        } else {
          return texcoord < that.texcoord;
        }
      } else {
        return position_or_flat < that.position_or_flat;
      }
    }

    bool operator==(const IndexType& that) const {
      return position_or_flat == that.position_or_flat &&
          texcoord == that.texcoord && normal == that.normal;
    }

    bool operator!=(const IndexType& that) const {
      return !operator==(that);
    }
  };
  typedef std::map<IndexType, int> MapType;
  
  int count_;
  std::vector<IndexType> table_;
  MapType map_;
};

// TODO: consider splitting this into a low-level parser and a high-level
// object.
class WavefrontObjFile {
 public:
  struct Group {
    std::string name;
    size_t start, end;
  };

  typedef std::vector<Group> GroupList;

  explicit WavefrontObjFile(FILE* fp) {
    ParseFile(fp);
  };

  const GroupList& groups() const { return groups_; }

  // Populate draw_meshes.
  void CreateDrawMeshes(std::vector<DrawMesh>* draw_meshes) {
    draw_meshes->push_back(DrawMesh());
    DrawMesh& draw_mesh = draw_meshes->back();
    IndexFlattener flattener(positions_.size() / positionDim());
    for (size_t i = 0; i < faces_.size(); i += 3) {
      // .OBJ files use 1-based indexing.
      const int position_index = faces_[i + 0] - 1;
      const int texcoord_index = faces_[i + 1] - 1;
      const int normal_index = faces_[i + 2] - 1;
      const std::pair<int, bool> flattened = flattener.GetFlattenedIndex(
          position_index, texcoord_index, normal_index);
      draw_mesh.indices.push_back(flattened.first);
      if (flattened.second) {
        for (size_t i = 0; i < positionDim(); ++i) {
          draw_mesh.attribs.push_back(
              positions_[positionDim() * position_index + i]);
        }
        if (texcoord_index == -1) {
          for (size_t i = 0; i < texcoordDim(); ++i) {
            draw_mesh.attribs.push_back(0);
          }
        } else {
          for (size_t i = 0; i < texcoordDim(); ++i) {
            draw_mesh.attribs.push_back(
                texcoords_[texcoordDim() * texcoord_index + i]);
          }
        }
        if (normal_index == -1) {
          for (size_t i = 0; i < normalDim(); ++i) {
            draw_mesh.attribs.push_back(0);
          }
        } else {
          for (size_t i = 0; i < normalDim(); ++i) {
            draw_mesh.attribs.push_back(
                normals_[normalDim() * normal_index + i]);
          }
        }
      }
    }
  }

  void DumpDebug() const {
    printf("positions size: %zu\ntexcoords size: %zu\nnormals size: %zu"
           "\nfaces size: %zu\n", positions_.size(), texcoords_.size(),
           normals_.size(), faces_.size());
  }
 private:
  WavefrontObjFile() { }
  
  void ParseFile(FILE* fp) {
    // TODO: don't use a fixed-size buffer.
    const size_t kLineBufferSize = 256;
    char buffer[kLineBufferSize];
    unsigned int line_num = 1;
    while (fgets(buffer, kLineBufferSize, fp) != NULL) {
      const char* stripped = buffer;
      while (isspace(*stripped)) {
        ++stripped;
      }
      ParseLine(stripped, line_num++);
    }
  }

  void ParseLine(const char* line, unsigned int line_num) {
    switch (*line) {
      case 'v':
        ParseAttrib(line + 1, line_num);
        break;
      case 'f':
        ParseFace(line + 1, line_num);
        break;
      case 'g':
        ParseGroup(line + 1, line_num);
        break;
      case '\0':
      case '#':
        break;  // Do nothing for comments or blank lines.
      case 'p':
        WarnLine("point unsupported", line_num);
        break;
      case 'l':
        WarnLine("line unspported", line_num);
        break;
      case 'u':
        ParseUsemtl(line + 6, line_num);
        break;
      case 'm':
        ParseMtllib(line + 6, line_num);
        break;
      case 's':
        ParseSmoothingGroup(line + 1, line_num);
        break;
      default:
        WarnLine("unknown keyword", line_num);
        break;
    }
  }

  void ParseAttrib(const char* line, unsigned int line_num) {
    ShortFloatList floats;
    floats.ParseLine(line + 1);
    if (isspace(*line)) {
      ParsePosition(floats, line_num);
    } else if (*line == 't') {
      ParseTexCoord(floats, line_num);
    } else if (*line == 'n') {
      ParseNormal(floats, line_num);
    } else {
      WarnLine("unknown attribute format", line_num);
    }
  }

  void ParsePosition(const ShortFloatList& floats, unsigned int line_num) {
    if (floats.size() != positionDim() &&
        floats.size() != 6) {  // ignore r g b for now.
      ErrorLine("bad position", line_num);
    }
    floats.AppendNTo(&positions_, positionDim());
  }

  void ParseTexCoord(const ShortFloatList& floats, unsigned int line_num) {
    if ((floats.size() < 1) || (floats.size() > 3)) {
      // TODO: correctly handle 3-D texcoords intead of just
      // truncating.
      ErrorLine("bad texcoord", line_num);
    }
    floats.AppendNTo(&texcoords_, texcoordDim());
  }

  void ParseNormal(const ShortFloatList& floats, unsigned int line_num) {
    if (floats.size() != normalDim()) {
      ErrorLine("bad normal", line_num);
    }
    floats.AppendTo(&normals_);
  }

  // Parses faces and converts to triangle fans. This is not a
  // particularly good tesselation in general case, but it is really
  // simple, and is perfectly fine for triangles and quads.
  void ParseFace(const char* line, unsigned int line_num) {
    // Also handle face outlines as faces.
    if (*line == 'o') ++line;
    
    // TODO: instead of storing these indices as-is, it might make
    // sense to flatten them right away. This can reduce memory
    // consumption and improve access locality, especially since .OBJ
    // face indices are so needlessly large.
    int indices[9] = { 0 };
    // The first index acts as the pivot for the triangle fan.
    line = ParseIndices(line, line_num, indices + 0, indices + 1, indices + 2);
    if (line == NULL) {
      ErrorLine("bad first index", line_num);
    }
    line = ParseIndices(line, line_num, indices + 3, indices + 4, indices + 5);
    if (line == NULL) {
      ErrorLine("bad second index", line_num);
    }
    // After the first two indices, each index introduces a new
    // triangle to the fan.
    while ((line = ParseIndices(line, line_num,
                                indices + 6, indices + 7, indices + 8))) {
      faces_.insert(faces_.end(), indices, indices + 9);
      // The most recent vertex is reused for the next triangle.
      indices[3] = indices[6];
      indices[4] = indices[7];
      indices[5] = indices[8];
      indices[6] = indices[7] = indices[8] = 0;
    }
  }

  // Parse a single group of indices, separated by slashes ('/').
  // TODO: convert negative indices (that is, relative to the end of
  // the current vertex positions) to more conventional positive
  // indices.
  const char* ParseIndices(const char* line, unsigned int line_num,
                           int* position_index, int* texcoord_index,
                           int* normal_index) {
    const char* endptr = NULL;
    *position_index = strtoint(line, &endptr);
    if (*position_index == 0) {
      return NULL;
    }
    if (endptr != NULL && *endptr == '/') {
      *texcoord_index = strtoint(endptr + 1, &endptr);
    } else {
      *texcoord_index = *normal_index = 0;
    }
    if (endptr != NULL && *endptr == '/') {
      *normal_index = strtoint(endptr + 1, &endptr);
    } else {
      *normal_index = 0;
    }
    return endptr;
  }
  
  void ParseGroup(const char* line, unsigned int line_num) {
    static bool once = true;
    if (once) {
      WarnLine("group unsupported", line_num);
      once = false;
    }
  }

  void ParseSmoothingGroup(const char* line, unsigned int line_num) {
    static bool once = true;
    if (once) {
      WarnLine("s unsupported", line_num);
      once = false;
    }
  }

  void ParseMtllib(const char* line, unsigned int line_num) {
    static bool once = true;
    if (once) {
      WarnLine("mtllib (?) unsupported", line_num);
      once = false;
    }
  }

  void ParseUsemtl(const char* line, unsigned int line_num) {
    static bool once = true;
    if (once) {
      WarnLine("usemtl (?) unsupported", line_num);
      once = false;
    }
  }

  void WarnLine(const char* why, unsigned int line_num) {
    fprintf(stderr, "WARNING: %s at line %u\n", why, line_num);
  }

  void ErrorLine(const char* why, unsigned int line_num) {
    fprintf(stderr, "ERROR: %s at line %u\n", why, line_num);
    exit(-1);
  }

  static size_t positionDim() { return 3; }
  static size_t texcoordDim() { return 2; }
  static size_t normalDim() { return 3; }
  
  AttribList positions_;
  AttribList texcoords_;
  AttribList normals_;
  // Indices are 1-indexed, and per-attrib.
  IndexList faces_;
  GroupList groups_;
};

// Axis-aligned bounding box
struct AABB {
  float mins[3];
  float maxes[3];
};

void DumpJsonFromAABB(const AABB& aabb) {
  printf("var aabb = { mins: [%f, %f, %f], maxes: [%f, %f, %f] };\n",
         aabb.mins[0], aabb.mins[1], aabb.mins[2],
         aabb.maxes[0], aabb.maxes[1], aabb.maxes[2]);
}

float UniformScaleFromAABB(const AABB& aabb) {
  const float x = aabb.maxes[0] - aabb.mins[0];
  const float y = aabb.maxes[1] - aabb.mins[1];
  const float z = aabb.maxes[2] - aabb.mins[2];
  return (x > y)
      ? ((x > z) ? x : z)
      : ((y > z) ? y : z);
}

void AABBToCenter(const AABB& aabb, float center[3]) {
  for (size_t i = 0; i < 3; ++i) {
    center[i] = 0.5*(aabb.mins[i] + aabb.maxes[i]);
  }
}

AABB AABBFromAttribs(const AttribList& interleaved_attribs) {
  AABB aabb;
  for (size_t i = 0; i < 3; ++i) {
    aabb.mins[i] = FLT_MAX;
    aabb.maxes[i] = -FLT_MAX;
  }
  for (size_t i = 0; i < interleaved_attribs.size(); i += 8) {
    for (size_t j = 0; j < 3; ++j) {
      const float attrib = interleaved_attribs[i + j];
      if (aabb.mins[j] > attrib) {
        aabb.mins[j] = attrib;
      }
      if (aabb.maxes[j] < attrib) {
        aabb.maxes[j] = attrib;
      }
    }
  }
  return aabb;
}

struct Bounds {
  float mins[8];
  float maxes[8];
};

float UniformScaleFromBounds(const Bounds& bounds) {
  const float x = bounds.maxes[0] - bounds.mins[0];
  const float y = bounds.maxes[1] - bounds.mins[1];
  const float z = bounds.maxes[2] - bounds.mins[2];
  return (x > y)
      ? ((x > z) ? x : z)
      : ((y > z) ? y : z);
}

Bounds BoundsFromAttribs(const AttribList& interleaved_attribs) {
  Bounds bounds;
  for (size_t i = 0; i < 8; ++i) {
    bounds.mins[i] = FLT_MAX;
    bounds.maxes[i] = -FLT_MAX;
  }
  for (size_t i = 0; i < interleaved_attribs.size(); i += 8) {
    for (size_t j = 0; j < 8; ++j) {
      const float attrib = interleaved_attribs[i + j];
      if (bounds.mins[j] > attrib) {
        bounds.mins[j] = attrib;
      }
      if (bounds.maxes[j] < attrib) {
        bounds.maxes[j] = attrib;
      }
    }
  }
  return bounds;
}

uint16 Quantize(float f, float offset, float range, int bits) {
  const float f_offset = f + offset;
  // Losslessly multiply a float by 1 << bits;
  const float f_scaled = ldexpf(f_offset, bits);
  // static_cast rounds towards zero (i.e. truncates).
  return static_cast<uint16>(f_scaled / range - 0.5f);
}

struct BoundsParams {
  static BoundsParams FromBounds(const Bounds& bounds) {
    BoundsParams ret;
    const float scale = UniformScaleFromBounds(bounds);
    // Position. Use a uniform scale.
    for (size_t i = 0; i < 3; ++i) {
      ret.offsets[i] = -bounds.mins[i];
      ret.scales[i] = scale;
      ret.bits[i] = 14;
    }
    // TexCoord.
    for (size_t i = 3; i < 5; ++i) {
      ret.offsets[i] = -bounds.mins[i];
      ret.scales[i] = bounds.maxes[i] - bounds.mins[i];
      ret.bits[i] = 10;
    }
    // Normal. Always uniform range.
    for (size_t i = 5; i < 8; ++i) {
      ret.offsets[i] = 1.f;
      ret.scales[i] = 2.f;
      ret.bits[i] = 10;
    }
    return ret;
  }

  void DumpJson() {
    puts("{");
    printf("  offsets: [%f,%f,%f,%f,%f,%f,%f,%f],\n",
           offsets[0], offsets[1], offsets[2], offsets[3],
           offsets[4], offsets[5], offsets[6], offsets[7]);
    printf("  scales: [%f,%f,%f,%f,%f,%f,%f,%f],\n",
           scales[0], scales[1], scales[2], scales[3],
           scales[4], scales[5], scales[6], scales[7]);
    printf("  bits: [%d,%d,%d,%d,%d,%d,%d,%d]\n",
           bits[0], bits[1], bits[2], bits[3],
           bits[4], bits[5], bits[6], bits[7]);
    puts("};");
  }
  
  float offsets[8];
  float scales[8];
  int bits[8];
};

// TODO: make "bounds_params" an in/out parameter.
void AttribsToQuantizedAttribs(const AttribList& interleaved_attribs,
                               BoundsParams* bounds_params,
                               QuantizedAttribList* quantized_attribs) {
  const Bounds bounds = BoundsFromAttribs(interleaved_attribs);
  quantized_attribs->resize(interleaved_attribs.size());
  *bounds_params = BoundsParams::FromBounds(bounds);
  for (size_t i = 0; i < interleaved_attribs.size(); i += 8) {
    for (size_t j = 0; j < 8; ++j) {
      quantized_attribs->at(i + j) = Quantize(interleaved_attribs[i + j],
                                              bounds_params->offsets[j],
                                              bounds_params->scales[j],
                                              bounds_params->bits[j]);
    }
  }
}

uint16 ZigZag(int16 word) {
  return (word >> 15) ^ (word << 1);
}

void CompressIndicesToUtf8(const OptimizedIndexList& list,
                           std::vector<char>* utf8) {
  // For indices, we don't do delta from the most recent index, but
  // from the high water mark. The assumption is that the high water
  // mark only ever moves by one at a time. Foruntately, the vertex
  // optimizer does that for us, to optimize for per-transform vertex
  // fetch order.
  uint16 index_high_water_mark = 0;
  for (size_t i = 0; i < list.size(); ++i) {
    const int index = list[i];
    CHECK(index >= 0);
    CHECK(index <= index_high_water_mark);
    CHECK(Uint16ToUtf8(index_high_water_mark - index, utf8));
    if (index == index_high_water_mark) {
      ++index_high_water_mark;
    }
  }
}

void CompressQuantizedAttribsToUtf8(const QuantizedAttribList& attribs,
                                    std::vector<char>* utf8) {
  for (size_t i = 0; i < 8; ++i) {
    // Use a transposed representation, and delta compression.
    uint16 prev = 0;
    for (size_t j = i; j < attribs.size(); j += 8) {
      const uint16 word = attribs[j];
      const uint16 za = ZigZag(static_cast<int16>(word - prev));
      prev = word;
      CHECK(Uint16ToUtf8(za, utf8));
    }     
  }
}

void CompressMeshToFile(const QuantizedAttribList& attribs,
                        const OptimizedIndexList& indices,
                        const char* fn) {
  CHECK((attribs.size() & 7) == 0);
  const size_t num_verts = attribs.size() / 8;
  CHECK(num_verts > 0);
  CHECK(num_verts < 65536);
  std::vector<char> utf8;
  CHECK(Uint16ToUtf8(static_cast<uint16>(num_verts - 1), &utf8));
  CompressQuantizedAttribsToUtf8(attribs, &utf8);
  CompressIndicesToUtf8(indices, &utf8);

  FILE* fp = fopen(fn, "wb");
  fwrite(&utf8[0], 1, utf8.size(), fp);
  fclose(fp);
}

#endif  // WEBGL_LOADER_MESH_H_
