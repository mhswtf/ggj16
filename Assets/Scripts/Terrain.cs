using UnityEngine;
using System.Collections;

public class Terrain : MonoBehaviour {

	// Use this for initialization
	void Start () {
        Mesh mf = GetComponent<MeshFilter>().mesh;
        mf.RecalculateNormals();
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
