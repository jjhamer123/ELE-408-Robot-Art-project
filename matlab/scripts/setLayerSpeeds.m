function setLayerSpeeds(speeds, layers, opts)
%SETLAYERSPEEDS  Set how fast each layer's motor turns in the Godot sim (ROS 2).
%
%   setLayerSpeeds([0.4 -0.8 1.2])     layer 1 at 0.4 rad/s, layer 2 at -0.8, layer 3 at 1.2
%   setLayerSpeeds(0.5, 2)             only layer 2 -> 0.5 rad/s (the others keep going)
%   setLayerSpeeds([0 0 0])            stop all three
%   setLayerSpeeds(w0 * [1 -2 3])      Fourier frequencies n_k times a base speed w0
%
%   speeds   rad/s, one per layer (+ = anticlockwise seen from above, ROS convention)
%   layers   which layers the speeds are for (default 1:numel(speeds))
%
%   The motors keep turning at these speeds until you send new ones.
%   Sends control_msgs/JointJog on /JointJog (joint1, joint2, ...), the topic the
%   Godot ROS2 node listens to in SIMULATION mode.
%
%   Options:
%     "MaxJointVelocity"  must equal "Max Joint Velocity" on Godot's ROS2 node
%                         (default 1.0 rad/s). JointJog speeds are sent as a
%                         fraction (-1..1) of it, so faster speeds get capped.
%     "Topic"             default "/JointJog"

arguments
    speeds (1,:) double {mustBeFinite}
    layers (1,:) double {mustBeInteger, mustBePositive} = 1:numel(speeds)
    opts.MaxJointVelocity (1,1) double {mustBePositive} = 1.0
    opts.Topic (1,1) string = "/JointJog"
end
if numel(layers) ~= numel(speeds)
    error("setLayerSpeeds:size", "Give one speed per layer: %d speeds but %d layers.", numel(speeds), numel(layers));
end

frac = speeds / opts.MaxJointVelocity;
if any(abs(frac) > 1)
    warning("setLayerSpeeds:capped", ...
        "Speeds above %.2f rad/s are capped by Godot. Raise ""Max Joint Velocity"" on the ROS2 node and pass the same value as ""MaxJointVelocity"".", ...
        opts.MaxJointVelocity);
    frac = max(min(frac, 1), -1);
end

pub = robotArtPublisher(opts.Topic, "control_msgs/JointJog");
msg = ros2message(pub);
msg.joint_names = arrayfun(@(k) sprintf('joint%d', k), layers, "UniformOutput", false);
msg.velocities = frac;
for i = 1:3          % repeated in case one is missed; sending the same speeds again is harmless
    send(pub, msg);
    pause(0.05);
end

fprintf("Layer speeds set:");
fprintf("  L%d = %.3f rad/s", [layers; frac * opts.MaxJointVelocity]);
fprintf("\n");
end
