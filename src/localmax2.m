function l = localmax2(f,t,w)
    % %  Find the argmax in detect function f around location t with
    %    sreaching window of width w
    halfw = round(w/2);
    sreach = intersect((1:length(f)),( t - halfw : t + halfw ));
    if sreach ~= 0
        [~,l] = max(f(sreach));
        l = l + t - halfw - 1;
    else
        l = [];
    end
end