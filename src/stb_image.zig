pub const stb_image = @cImport({
    @cInclude("stb_image.h");
});

pub fn loadImage(filename: []const u8, width: *i32, height: *i32, channels_in_file: *i32) [*]u8 {
    stb_image.stbi_set_flip_vertically_on_load(1);
    return stb_image.stbi_load(@ptrCast(filename), width, height, channels_in_file, 0);
}

pub fn freeImage(data: [*]u8) void {
    stb_image.stbi_image_free(data);
}
