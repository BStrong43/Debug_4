/*
	Copyright 2011-2020 Daniel S. Buckstein

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/

/*
	animal3D SDK: Minimal 3D Animation Framework
	By Daniel S. Buckstein
	
	passTangentBasis_transform_vs4x.glsl
	Calculate and pass view-space tangent basis.
*/

#version 430

layout (location = 10)	in vec4 aTangent;
layout (location = 11)	in vec4 aBitangent;
layout (location = 2)	in vec4 aNormal;
layout (location = 0)	in vec4 aPosition;
layout (location = 8)	in vec4 aTexcoord;

layout (location = 0)	uniform mat4 uP;
layout (location = 16)	uniform mat4 uMV;
layout (location = 32)	uniform mat4 uMV_nrm;
layout (location = 48)	uniform mat4 uAtlas;

//uniform vbVertexData {
//	layout (location = 64) mat4 vTangentBasis_view;
//	layout (location = 72)	vec4 vTexcoord_atlas;
//};

layout (location = 0) out mat4 vTangentBasis_view;
layout (location = 16) out	vec4 vTexcoord_atlas;

void main()
{
	vec4 position_view = uMV * aPosition;
	mat4 tangentbasis = mat4(aTangent, aBitangent, aNormal, aPosition);
	vTangentBasis_view = uMV_nrm * tangentbasis;
	vTangentBasis_view[3] = position_view;

	gl_Position = uP * position_view;
	vTexcoord_atlas = uAtlas * aTexcoord;
}
