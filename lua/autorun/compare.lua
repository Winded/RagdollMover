
-- Functions for comparing different datatypes

function VectorWithin(vector, minBounds, maxBounds)

	local vX = vector.x >= minBounds.x and vector.x <= maxBounds.x;
	local vY = vector.y >= minBounds.y and vector.y <= maxBounds.y;
	local vZ = vector.z >= minBounds.z and vector.z <= maxBounds.z;

	return vX and vY and vZ;

end