using UnityEngine;
using System.Collections;
using System;
using System.Collections.Generic;

public class MeshGenerator : MonoBehaviour {

    [Range(10, 250)]
    public int size = 100;

    [Range(.1f, 20f)]
    public float spacing = 1f;

    [Range(.1f, 100f)]
    public float terrainHeight = 10f;

    [Range(0f, 100f)]
    public float waterLevel = 10f;

    public Material terrainMaterial;
    public Material waterMaterial;

    public List<Texture2D> textures = new List<Texture2D>();

    private MeshFilter terrain, water;

    public void GenerateTerrain() {

        if (terrain == null) {
            Transform tt = transform.FindChild("Terrain");

            if (tt != null) { 
                terrain = tt.GetComponent<MeshFilter>();
            } else {
                GameObject obj = new GameObject();

                obj.name = "Terrain";
                obj.transform.SetParent(transform);
                obj.AddComponent<MeshRenderer>();

                terrain = obj.AddComponent<MeshFilter>();
            }
        }

        int w = textures[0].width;
        int h = textures[0].height;

        Texture2D composite = new Texture2D(w, h);

        Color[] pixels = composite.GetPixels();

        Color[][] source = new Color[textures.Count][];

        for (int i = 0; i < textures.Count; i++) {
            source[i] = textures[i].GetPixels();
        }

        for (int i = 0; i < pixels.Length; i++) {
            float total = 0f;

            for (int j = 0; j < source.Length; j++) {
                total += source[j][i].r;
            }

            float avg = total / (float) source.Length;

            pixels[i].r = avg;
        }

        composite.SetPixels(pixels);
        composite.Apply();

        terrain.GetComponent<Renderer>().material = terrainMaterial;
        terrain.mesh = CreateTerrainMesh(composite, size, terrainHeight, spacing);
        terrain.transform.localPosition = Vector3.zero;
    }

    private Mesh CreateTerrainMesh(Texture2D image, int size, float height, float spacing) {
        if (image == null) throw new ArgumentNullException("Image texture was null");

        int w = size;
        int h = size;

        Color[] pixels = image.GetPixels();

        Vector3[] vertices = new Vector3[w * h];
        Vector2[] uvs = new Vector2[vertices.Length];

        float factor = (float) image.width / (float) w ;

        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int i = y * w + x;

                int px = (int) Mathf.Round(x * factor);
                int py = (int) Mathf.Round(y * factor);
                int pi = py * image.width + px;

                float vx = x - (float) (w - 1) / 2f;
                float vz = y - (float) (h - 1) / 2f;
                float vy = pixels[pi].r * height;

                vertices[i] = new Vector3(vx * spacing, vy, vz * spacing);

                uvs[i] = new Vector2((float) x / (float) w, (float) y / (float) h);
            }
        }

        int[] triangles = new int[6 * (w - 1) * (h - 1)];

        for (int y = 0; y < h - 1; y++) {
            for (int x = 0; x < w - 1; x++) {

                // Current vertex
                int v = y * w + x;

                // Current triangle
                int i = (y * (w - 1) + x) * 6;

                // Black or white square (chess analogy)
                int o = (x + y) % 2;

                // Clockwise!

                triangles[i] = v + o * w;
                triangles[i + 1] = v + w + o;
                triangles[i + 2] = v + (1 - o) * w + 1;

                triangles[i + 3] = v;
                triangles[i + 4] = v + w + 1 - o;
                triangles[i + 5] = v + 1;
            }
        }

        Mesh mesh = new Mesh();
        mesh.name = "TerrainMesh";

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uvs;

        mesh.RecalculateNormals();

        return mesh;
    }

    public void GenerateWater() {

        if (water == null) {
            Transform wt = transform.FindChild("Water");

            if (wt != null) {
                water = wt.GetComponent<MeshFilter>();

            } else {
                GameObject obj = new GameObject();

                obj.name = "Water";
                obj.transform.SetParent(transform);
                MeshRenderer renderer = obj.AddComponent<MeshRenderer>();
                renderer.material = terrainMaterial;

                water = obj.AddComponent<MeshFilter>();
            }
        }

        water.GetComponent<Renderer>().material = waterMaterial;
        water.mesh = CreateWaterMesh(size, terrainHeight, spacing);
        water.transform.localPosition = new Vector3(0f, waterLevel, 0f);

    }

    private Mesh CreateWaterMesh(int size, float height, float spacing) {

        int w = size;
        int h = size;

        Vector3[] vertices = new Vector3[w * h];
        Vector2[] uvs = new Vector2[vertices.Length];

        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int i = y * w + x;

                float vx = x - (float) (w - 1) / 2f;
                float vz = y - (float) (h - 1) / 2f;
                float vy = 0f;

                vertices[i] = new Vector3(vx * spacing, vy, vz * spacing);
                uvs[i] = new Vector2((float) x / (float) w, (float) y / (float) h);
            }
        }

        int[] triangles = new int[6 * (w - 1) * (h - 1)];

        for (int y = 0; y < h - 1; y++) {
            for (int x = 0; x < w - 1; x++) {

                // Current vertex
                int v = y * w + x;

                // Current triangle
                int i = (y * (w - 1) + x) * 6;

                // Black or white square (chess analogy)
                int o = (x + y) % 2;

                // Clockwise!

                triangles[i] = v + o * w;
                triangles[i + 1] = v + w + o;
                triangles[i + 2] = v + (1 - o) * w + 1;

                triangles[i + 3] = v;
                triangles[i + 4] = v + w + 1 - o;
                triangles[i + 5] = v + 1;
            }
        }

        Mesh mesh = new Mesh();
        mesh.name = "WaterMesh";

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uvs;

        mesh.RecalculateNormals();

        return mesh;
    }
}
