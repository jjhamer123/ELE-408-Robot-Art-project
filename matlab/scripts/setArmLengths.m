function setArmLengths(lengths, layers, opts)
%SETARMLENGTHS  Move each layer's clamp B so its arm is this long in the Godot sim (ROS 2).
%
%   setArmLengths([0.12 0.05 0.03])    layer 1 arm 120 mm, layer 2 50 mm, layer 3 30 mm
%   setArmLengths(0.08, 2)             only layer 2 -> 80 mm
%
%   lengths  metres, one per layer (motor axis to the next layer / pen), 0.03 .. 0.17
%   layers   which layers the lengths are for (default 1:numel(lengths))
%
%   The clamps slide to the new length (about 50 mm/s), so allow a moment before
%   drawing. It works while the motors are turning, and is separate from
%   setLayerSpeeds.
%   Sends sensor_msgs/JointState (clampB1, clampB2, ... positions) on
%   /robot_art/set_positions. Godot's ROS2 node needs the updated ros_2_arm.gd and must
%   be in SIMULATION mode.
%
%   Options:
%     "Topic"   default "/robot_art/set_positions" ("Set Position Topic" on the ROS2 node)

arguments
    lengths (1,:) double {mustBeFinite}
    layers (1,:) double {mustBeInteger, mustBePositive} = 1:numel(lengths)
    opts.Topic (1,1) string = "/robot_art/set_positions"
end
if numel(layers) ~= numel(lengths)
    error("setArmLengths:size", "Give one length per layer: %d lengths but %d layers.", numel(lengths), numel(layers));
end

R_MIN = 0.03;  R_MAX = 0.17;     % clamp B travel (m)
if any(lengths < R_MIN | lengths > R_MAX)
    warning("setArmLengths:range", "Arm lengths must be %.0f..%.0f mm; values outside are clamped.", R_MIN*1000, R_MAX*1000);
    lengths = min(max(lengths, R_MIN), R_MAX);
end

pub = robotArtPublisher(opts.Topic, "sensor_msgs/JointState");
msg = ros2message(pub);
msg.name = arrayfun(@(k) sprintf('clampB%d', k), layers, "UniformOutput", false);
msg.position = lengths;
for i = 1:3          % repeated in case one is missed; sending the same targets again is harmless
    send(pub, msg);
    pause(0.05);
end

fprintf("Arm lengths set:");
fprintf("  L%d = %.1f mm", [layers; lengths * 1000]);
fprintf("\n");
end
