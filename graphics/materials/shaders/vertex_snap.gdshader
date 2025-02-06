shader_type spatial;
uniform float snap_size = 0.125;

void vertex() {
    VERTEX = floor(VERTEX / snap_size) * snap_size;
}