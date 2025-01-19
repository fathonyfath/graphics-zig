const std = @import("std");
const freetype = @import("freetype");
const font_assets = @import("font-assets");
const zm = @import("zm");
const gl = @import("gl");
const Shader = @import("Shader.zig");

pub const Vec2i = zm.vec.Vec(2, i32);

const vertex_shader_content =
    \\#version 330 core
    \\layout (location = 0) in vec4 vertex;
    \\
    \\out vec2 TexCoords;
    \\
    \\uniform mat4 projection;
    \\
    \\void main() {
    \\  gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    \\  TexCoords = vertex.zw;
    \\}
    \\
;

const fragment_shader_content =
    \\#version 330 core
    \\
    \\in vec2 TexCoords;
    \\
    \\out vec4 color;
    \\
    \\uniform sampler2D text;
    \\uniform vec3 textColor;
    \\
    \\void main() {
    \\  vec4 sampled = vec4(1.0, 1.0, 1.0, texture(text, TexCoords).r);
    \\  color = vec4(textColor, 1.0) * sampled;
    \\}
    \\
;

pub const Character = struct {
    texture_id: u32,
    size: Vec2i,
    bearing: Vec2i,
    advance: u32,
};

var library: freetype.Library = undefined;
var face: freetype.Face = undefined;

const CharacterMap = std.AutoArrayHashMap(u8, Character);

var character_map: CharacterMap = undefined;

var shader: Shader = undefined;

var VAO: u32 = undefined;
var VBO: u32 = undefined;

pub fn init() void {
    shader = Shader.create(vertex_shader_content, fragment_shader_content);

    library = freetype.Library.init() catch unreachable;
    defer library.deinit();

    face = library.createFaceMemory(font_assets.fira_sans_regular_ttf, 0) catch unreachable;
    defer face.deinit();

    face.setPixelSizes(0, 48) catch unreachable;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    character_map = CharacterMap.init(allocator);

    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1);

    inline for (0..128) |i| {
        face.loadChar(@as(u32, i), freetype.LoadFlags{ .render = true }) catch unreachable;
        var texture_id: u32 = undefined;
        gl.GenTextures(1, @ptrCast(&texture_id));
        gl.BindTexture(gl.TEXTURE_2D, texture_id);
        gl.TexImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RED,
            @intCast(face.glyph().bitmap().width()),
            @intCast(face.glyph().bitmap().rows()),
            0,
            gl.RED,
            gl.UNSIGNED_BYTE,
            @ptrCast(face.glyph().bitmap().buffer()),
        );
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        character_map.put(i, .{
            .texture_id = texture_id,
            .size = .{ @intCast(face.glyph().bitmap().width()), @intCast(face.glyph().bitmap().rows()) },
            .bearing = .{ face.glyph().bitmapLeft(), face.glyph().bitmapTop() },
            .advance = @intCast(face.glyph().advance().x),
        }) catch unreachable;
    }

    {
        const projection = zm.Mat4f.orthographic(0, 800, 0, 600, 0, 600);

        shader.use();
        gl.UniformMatrix4fv(gl.GetUniformLocation(shader.program, "projection"), 1, gl.TRUE, @ptrCast(&projection.data));
    }

    {
        gl.GenVertexArrays(1, @ptrCast(&VAO));
        gl.GenBuffers(1, @ptrCast(&VBO));

        gl.BindVertexArray(VAO);
        gl.BindBuffer(gl.ARRAY_BUFFER, VBO);

        defer {
            gl.BindVertexArray(0);
            gl.BindBuffer(gl.ARRAY_BUFFER, 0);
        }

        gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * 4 * 6, null, gl.DYNAMIC_DRAW);

        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, @sizeOf(f32) * 4, 0);
    }
}

pub fn renderText(text: []const u8, x: f32, y: f32, scale: f32, color: zm.Vec3f) void {
    shader.use();
    gl.Uniform3f(gl.GetUniformLocation(shader.program, "textColor"), color[0], color[1], color[2]);
    gl.ActiveTexture(gl.TEXTURE0);
    gl.BindVertexArray(VAO);
    defer gl.BindVertexArray(0);

    var char_x: f32 = x;

    for (text) |c| {
        const character = character_map.get(c) orelse unreachable;

        const x_pos: f32 = char_x + @as(f32, @floatFromInt(character.bearing[0])) * scale;
        const y_pos: f32 = y - @as(f32, @floatFromInt((character.size[1] - character.bearing[1]))) * scale;

        const w: f32 = @as(f32, @floatFromInt(character.size[0])) * scale;
        const h: f32 = @as(f32, @floatFromInt(character.size[1])) * scale;

        const vertices = [_]f32{
            x_pos,     y_pos + h, 0.0, 0.0,
            x_pos,     y_pos,     0.0, 1.0,
            x_pos + w, y_pos,     1.0, 1.0,

            x_pos,     y_pos + h, 0.0, 0.0,
            x_pos + w, y_pos,     1.0, 1.0,
            x_pos + w, y_pos + h, 1.0, 0.0,
        };
        gl.BindTexture(gl.TEXTURE_2D, character.texture_id);
        {
            gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
            defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);
            gl.BufferSubData(gl.ARRAY_BUFFER, 0, @sizeOf(@TypeOf(vertices)), @ptrCast(&vertices));
        }

        gl.DrawArrays(gl.TRIANGLES, 0, 6);
        char_x += @as(f32, @floatFromInt(character.advance >> 6)) * scale;
    }

    gl.BindTexture(gl.TEXTURE_2D, 0);
}
