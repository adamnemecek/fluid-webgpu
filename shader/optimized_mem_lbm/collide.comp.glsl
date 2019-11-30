layout(local_size_x = 16, local_size_y = 16) in;

#include "optimized_mem_lbm/code_block/layout_and_fn.glsl"

layout(set = 1, binding = 0) uniform Q9DirectionUniform {
  uint direction;
  float any[254];
};

void main() {
  uvec2 uv = uvec2(gl_GlobalInvocationID.xy);
  if (uv.x >= lattice_num.x || uv.y >= lattice_num.y) {
    return;
  }
  uint destIndex = fieldIndex(uv);
  vec4 macro = macro_info[destIndex];
  int material = int(macro.w);
  // at boundary lattice, not need calculate collide and stream
  if (isBounceBackCell(material) || isLidDrivenCell(material)) {
    return;
  }

  vec2 velocity = macro.xy;
  float rho = macro.z;

  // Collision step: fout = fin - omega * (fin - feq)
  float usqr = 1.5 * (velocity.x * velocity.x + velocity.y * velocity.y);
  float f_i = collid_streaming_cells[latticeIndex(uv) + direction];
  // rest population on lattice center not need stream
  if (direction == 0) {
    collid_streaming_cells[latticeIndex(uv)] =
        f_i - omega() * (f_i - equilibrium(velocity, rho, direction, usqr));
  } else {
    temp_scalar_cells[destIndex] =
        f_i - omega() * (f_i - equilibrium(velocity, rho, direction, usqr));
  }
}