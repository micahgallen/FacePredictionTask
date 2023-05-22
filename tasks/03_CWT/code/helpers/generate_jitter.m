function jitter = generate_jitter(min_jitter, max_jitter)
    % Generate a single random jitter time
    jitter = min_jitter + (max_jitter - min_jitter) * rand;
end