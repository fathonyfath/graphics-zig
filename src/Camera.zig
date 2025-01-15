const std = @import("std");
const zm = @import("zm");
const math = std.math;
const sin = math.sin;
const cos = math.cos;
const toRadians = math.degreesToRadians;

const DEFAULT_YAW = -90.0;
const DEFAULT_PITCH = 0.0;

position: zm.Vec3f,
front: zm.Vec3f,
up: zm.Vec3f,
right: zm.Vec3f,
world_up: zm.Vec3f,
yaw: f32,
pitch: f32,

const Camera = @This();

pub fn createWithDefaults(position: zm.Vec3f, world_up: zm.Vec3f) Camera {
    return Camera.create(position, world_up, DEFAULT_YAW, DEFAULT_PITCH);
}

pub fn create(position: zm.Vec3f, world_up: zm.Vec3f, yaw: f32, pitch: f32) Camera {
    const front = calculateFront(yaw, pitch);
    const right = calculateRight(front, world_up);
    const up = calculateUp(right, front);

    return .{
        .position = position,
        .front = front,
        .up = up,
        .right = right,
        .world_up = world_up,
        .yaw = yaw,
        .pitch = pitch,
    };
}

pub fn translate(self: *Camera, translation: zm.Vec3f) void {
    self.position += translation;
}

pub fn rotate(self: *Camera, x: f32, y: f32) void {
    self.yaw += x;
    self.pitch += y;

    if (self.pitch > 89.0) self.pitch = 89.0;
    if (self.pitch < -89.0) self.pitch = -89.0;

    self.front = calculateFront(self.yaw, self.pitch);
    self.right = calculateRight(self.front, self.world_up);
    self.up = calculateUp(self.right, self.front);
}

pub fn getViewMatrix(self: Camera) zm.Mat4f {
    return zm.Mat4f.lookAt(self.position, self.position + self.front, self.up);
}

fn calculateFront(yaw: f32, pitch: f32) zm.Vec3f {
    return .{
        cos(toRadians(yaw)) * cos(toRadians(pitch)),
        sin(toRadians(pitch)),
        sin(toRadians(yaw)) * cos(toRadians(pitch)),
    };
}

fn calculateRight(front: zm.Vec3f, world_up: zm.Vec3f) zm.Vec3f {
    return zm.vec.normalize(zm.vec.cross(front, world_up));
}

fn calculateUp(right: zm.Vec3f, front: zm.Vec3f) zm.Vec3f {
    return zm.vec.normalize(zm.vec.cross(right, front));
}
