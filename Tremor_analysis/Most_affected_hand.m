function AffectedSide = Most_affected_hand (subject)
% Find most affected side using task files

if any(contains({sbjct.taskdir.name},"Right"))
    AffectedSide = 'Right';
elseif any(contains({sbjct.taskdir.name},"Left"))
    AffectedSide = 'Left';
end

end
