using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using UnityEditor;

public class NoiseGenerator : MonoBehaviour {

    private static GameObject canvasPrefab;

    private Texture2D image;
    private Renderer canvas;

    private string typeName;

    public bool HasTexture() {
        return image != null;
    }

    public void Save() {
        string fileName = FileIO.ExportToPNG(image.EncodeToPNG(), typeName);
        AssetDatabase.Refresh();

        string path = string.Format("Assets{0}{1}", FileIO.relativePath, fileName);

        AssetDatabase.ImportAsset(path);
        TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;

        importer.textureType = TextureImporterType.Advanced;
        importer.isReadable = true;
        importer.name = fileName;

        AssetDatabase.WriteImportSettingsIfDirty(path);
    }

    public void AddToMeshGenerator() {
        MeshGenerator.Instance.textures.Add(image);
    }

    public void Clear() {
        DestroyImmediate(canvas.gameObject);
        canvas = null;
        image = null;
    }

    public void DiamonSquare(int size, int iterations, float variation, float roughness, float seed) {
        DiamondSquareNoise noise = new DiamondSquareNoise(size, iterations, variation, roughness, seed);
        float[,] values = noise.Generate();

        Generate(values);

        typeName = "DS";
    }

    public void Cellular(int size, CellularNoise.NeighbourhoodType type, int iterations, int neighborhoodSize, float limit, float variance, float decay) {
        CellularNoise noise = new CellularNoise(size, type, iterations, neighborhoodSize, limit, variance, decay);
        float[,] values = noise.Generate();

        Generate(values);

        typeName = "CA";
    }

    private void Generate(float[,] values) {

        if (canvas == null) {
            if (canvasPrefab == null) {
                canvasPrefab = Resources.Load<GameObject>("Prefabs/Canvas");
            }

            GameObject obj = Instantiate<GameObject>(canvasPrefab);
            obj.name = "Canvas";
            obj.transform.SetParent(transform);
            canvas = obj.GetComponent<Renderer>();
        }

        int w = values.GetLength(0);
        int h = values.GetLength(1);

        image = new Texture2D(w, h);
        image.wrapMode = TextureWrapMode.Clamp;

        Color[] pixels = image.GetPixels();

        int i = 0;

        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                i = y * w + x;

                float value = values[x, y];
                SetBlackAndWhite(ref pixels[i], value);
            }
        }

        image.SetPixels(pixels);
        image.Apply();
        canvas.sharedMaterial.mainTexture = image;

    }

    private void SetBlackAndWhite(ref Color pixel, float value) {
        pixel.r = value;
        pixel.g = value;
        pixel.b = value;
        pixel.a = 1f;
    }
}

