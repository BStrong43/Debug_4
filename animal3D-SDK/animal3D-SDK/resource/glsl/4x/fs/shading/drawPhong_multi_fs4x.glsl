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
	
	drawPhong_multi_fs4x.glsl
	Calculate Phong shading model.
*/

#version 430

#define MAX_LIGHTS 4

in vbVertexData {
	layout (location = 0)	mat4 vTangentBasis_view;
	layout (location = 16)	vec4 vTexcoord_atlas;
};

layout (location = 64)	uniform vec4 uColor;
layout (location = 80)	uniform int uCount;
layout (binding = 0)	uniform sampler2D uTex_dm;
layout (binding = 1)	uniform sampler2D uTex_sm;

struct sPointLight
{
	vec4 worldPos;
	vec4 viewPos;
	vec4 color;
	float radius;
	float radiusInvSq;
	float radiusInv;
};
layout (binding = 4)	uniform ubPointLight {
	sPointLight uPointLight[MAX_LIGHTS];
};

layout (location = 0)	out vec4 rtFragColor;
layout (location = 1)	out vec4 rtPosition;
layout (location = 2)	out vec4 rtNormal;
layout (location = 3)	out vec4 rtTexcoord;
layout (location = 4)	out vec4 rtDiffuseMapSample;
layout (location = 5)	out vec4 rtSpecularMapSample;
layout (location = 6)	out vec4 rtDiffuseLightTotal;
layout (location = 7)	out vec4 rtSpecularLightTotal;


float pow64(float v)
{
	v *= v;	// ^2
	v *= v;	// ^4
	v *= v;	// ^8
	v *= v;	// ^16
	v *= v;	// ^32
	v *= v;	// ^64
	return v;
}


vec3 refl(in vec3 v, in vec3 n, in float d)
{
	return ((2.0 * d) * n - v);
}


float calcDiffuseCoefficient(
	out vec3 lightVec, out float lightDist, out float lightDistSq,
	in vec3 lightPos, in vec3 fragPos, in vec3 fragNrm)
{
	lightVec = lightPos - fragPos;
	lightDistSq = dot(lightVec, lightVec);
	lightDist = sqrt(lightDistSq);
	lightVec /= lightDist;
	return dot(lightVec, fragNrm);
}


float calcSpecularCoefficient(
	out vec3 reflVec, out vec3 eyeVec,
	in vec3 lightVec, in float diffuseCoefficient,
	in vec3 fragPos, in vec3 fragNrm, in vec3 eyePos)
{
	reflVec = refl(lightVec, fragNrm, diffuseCoefficient);
	eyeVec = normalize(eyePos - fragPos);
	return dot(reflVec, eyeVec);
}


float calcAttenuation(
	float lightDist, float lightDistSq,
	float lightSz, float lightSzInvSq, float lightSzInv)
{
	float atten = (1.0 / (1.0 + 2.0 * lightDist * lightSzInv + lightDistSq * lightSzInvSq));
	return atten;
}


void addPhongComponents(
	inout vec3 diffuseLightTotal, out float diffuseCoefficient,
	inout vec3 specularLightTotal, out float specularCoefficient,
	in vec3 lightPos, in vec3 lightCol,
	in float lightSz, in float lightSzInvSq, in float lightSzInv,
	in vec3 fragPos, in vec3 fragNrm, in vec3 eyePos)
{
	float lightDist, lightDistSq, attenuation;
	vec3 lightVec, reflVec, eyeVec;
	vec3 attenuationColor;

	diffuseCoefficient = calcDiffuseCoefficient(
		lightVec, lightDist, lightDistSq,
		lightPos, fragPos, fragNrm);
	specularCoefficient = calcSpecularCoefficient(
		reflVec, eyeVec,
		lightVec, diffuseCoefficient,
		fragPos, fragNrm, eyePos);
	attenuation = calcAttenuation(
		lightDist, lightDistSq,
		lightSz, lightSzInvSq, lightSzInv);

	diffuseCoefficient = max(0.0, diffuseCoefficient);
	specularCoefficient = pow64(max(0.0, specularCoefficient));

	attenuationColor = attenuation * lightCol;
	diffuseLightTotal += attenuationColor * diffuseCoefficient;
	specularLightTotal += attenuationColor * specularCoefficient;
}


void main()
{
	vec4 normal_view = normalize(vTangentBasis_view[2]);
	vec4 position_view = vTangentBasis_view[3];
	
	int i;
	sPointLight light;
	float kd, ks;
	vec3 eyePos = vec3(0.0);
	vec3 ambient = uColor.rgb * 0.1,
		diffuseLightTotal = vec3(0.0),
		specularLightTotal = diffuseLightTotal;
	int lightCt = uCount;

	for (i = 0; i < lightCt; ++i)
	{
		light = uPointLight[i];
		addPhongComponents(
			diffuseLightTotal, kd,
			specularLightTotal,ks,
			light.viewPos.xyz, light.color.rgb,
			light.radius, light.radiusInvSq, light.radiusInv,
			position_view.xyz, normal_view.xyz, eyePos);
	}

	vec4 sample_tex_dm = texture(uTex_dm, vTexcoord_atlas.xy);
	vec4 sample_tex_sm = texture(uTex_sm, vTexcoord_atlas.xy);

	rtFragColor.rgb = ambient
					+ sample_tex_dm.rgb * diffuseLightTotal
					+ sample_tex_sm.rgb * specularLightTotal;
	rtFragColor.a = sample_tex_dm.a;

	rtPosition = position_view;
	rtNormal = vec4(normal_view.xyz * 0.5 + 0.5, 1.0);
	rtTexcoord = vTexcoord_atlas;
	rtDiffuseMapSample = sample_tex_dm;
	rtSpecularMapSample = sample_tex_sm;
	rtDiffuseLightTotal = vec4(diffuseLightTotal, 1.0);
	rtSpecularLightTotal = vec4(specularLightTotal, 1.0);
}
