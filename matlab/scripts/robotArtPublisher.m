function pub = robotArtPublisher(topic, msgType)
%ROBOTARTPUBLISHER  One shared ROS 2 node + publisher per topic for the Robot Art
%   functions (setLayerSpeeds, setArmLengths). Made the first time a topic is used,
%   then reused, so calling the functions in a loop is cheap.
%
%   robotArtPublisher("reset")   delete the node and publishers (e.g. after
%                                changing ROS_DOMAIN_ID or if ROS got stuck)

persistent node pubs
if nargin == 1 && strcmpi(topic, "reset")
    pubs = [];
    node = [];
    pub = [];
    return
end

if isempty(node) || ~isvalid(node)
    node = ros2node("/matlab_robot_art");
    pubs = containers.Map();
end
key = char(topic);
if ~isKey(pubs, key)
    pubs(key) = ros2publisher(node, key, msgType);
    pause(1);   % give ROS 2 discovery time to find Godot's subscriber,
                % otherwise the very first message can be lost
end
pub = pubs(key);
end
