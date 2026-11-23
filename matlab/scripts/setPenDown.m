function setPenDown(down, opts)
%SETPENDOWN  Put the pen down (true) or lift it (false) in the Godot sim (ROS 2).
%
%   setPenDown(true)     pen down: it draws on the paper
%   setPenDown(false)    pen up: the arms keep moving but nothing is drawn
%
%   Sends std_msgs/Bool on /pen_down_demand. Godot's PenLift node moves the pen
%   (taking its Move Time) and publishes where it actually is on /pen_down_pos.
%   Both are logged as columns in the pen_xy CSV.
%
%   Read the pen back:  sub = ros2subscriber(ros2node("/pen_check"), "/pen_down_pos", "std_msgs/Bool");
%                       m = receive(sub, 2); m.data
%
%   Options:  "Topic"  default "/pen_down_demand"

arguments
    down (1,1) logical
    opts.Topic (1,1) string = "/pen_down_demand"
end

pub = robotArtPublisher(opts.Topic, "std_msgs/Bool");
msg = ros2message(pub);
msg.data = down;
for i = 1:3          % repeated in case one is missed; sending the same state again is harmless
    send(pub, msg);
    pause(0.02);
end
if down
    fprintf("Pen down\n");
else
    fprintf("Pen up\n");
end
end