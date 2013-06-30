# Extend an object with the values of other objects
exports.extend = (objects...) ->
    original = objects[0]
    for object in objects[1..]
        for own key, value of object
            original[key] = value
    return original
