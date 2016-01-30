using UnityEngine;
using System.Collections;

public class BennosAwesomeScript : MonoBehaviour {

	Renderer renderer;
	Camera camera;
	
	public float _Near = 0.3f;
	public float _Far = 1000f;
	public float depth = 0.5f;
	public float worldDepth = 0;
	
	void Start(){
		camera = Camera.main;
		renderer = GetComponent<Renderer>();
	}
	
	// Update is called once per frame
	void Update () {
		Matrix4x4 mat = (camera.projectionMatrix * camera.worldToCameraMatrix).inverse;
		renderer.material.SetMatrix("_ViewProjectInverse", mat);
		
		worldDepth = (_Near*_Far)/(_Far*(-depth) + _Far + _Near*depth);
		
	}
}
