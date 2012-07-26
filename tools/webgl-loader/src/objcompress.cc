#if 0  // A cute trick to making this .cc self-building from shell.
g++ $0 -O2 -Wall -Werror -o `basename $0 .cc`;
exit;
#endif
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

#include <sstream>

#include "mesh.h"
#include "optimize.h"

int main(int argc, const char* argv[]) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s in.obj out.utf8\n\n"
            "\tCompress in.obj to out.utf8 and write bounds to STDOUT.\n\n",
            argv[0]);
    return -1;
  }
  FILE* fp = fopen(argv[1], "r");
  WavefrontObjFile obj(fp);
  fclose(fp);
  std::vector<DrawMesh> meshes;
  obj.CreateDrawMeshes(&meshes);
  QuantizedAttribList attribs;
  BoundsParams bounds_params;
  AttribsToQuantizedAttribs(meshes[0].attribs, &bounds_params, &attribs);
  WebGLMeshList webgl_meshes;
  VertexOptimizer vertex_optimizer(attribs, meshes[0].indices);
  vertex_optimizer.GetOptimizedMeshes(&webgl_meshes);
  if (webgl_meshes.size() > 1) {
    CHECK(26 >= webgl_meshes.size());
    for (size_t i = 0; i < webgl_meshes.size(); ++i) {
      std::string out(argv[2]);
      // Strip off trailing ".utf8" if present.
      if ((5 < out.size()) && (out.substr(out.size() - 5) == ".utf8")) {
        out = out.substr(0, out.size() - 5);
      }
      out += '.';
      out += 'A' + i;
      out += ".utf8";
      CompressMeshToFile(webgl_meshes[i].attribs, webgl_meshes[i].indices,
                         out.c_str());
    }
  } else {
    CHECK(1 == webgl_meshes.size());
    CompressMeshToFile(webgl_meshes[0].attribs, webgl_meshes[0].indices,
                       argv[2]);
  }
  bounds_params.DumpJson();
  return 0;
}
