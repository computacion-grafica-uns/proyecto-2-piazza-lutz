using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(LuzGlobalManager))]
public class LuzGlobalManagerEditor : Editor
{
    private void OnSceneGUI()
    {
        LuzGlobalManager luzManager = (LuzGlobalManager)target;
        Handles.color = Color.white;

        // --- Punctual Light Position ---
        EditorGUI.BeginChangeCheck();
        Vector3 newPunctualPos = Handles.PositionHandle(luzManager._PunctualLightPosition, Quaternion.identity);
        if (EditorGUI.EndChangeCheck())
        {
            Undo.RecordObject(luzManager, "Move Punctual Light");
            luzManager._PunctualLightPosition = newPunctualPos;
            luzManager.UpdateAllMaterials();
        }

        // --- Directional Light Direction ---
        EditorGUI.BeginChangeCheck();
        Vector3 newDirDir = Handles.PositionHandle(luzManager.transform.position + luzManager._DirectionalLightDirection, Quaternion.identity);
        if (EditorGUI.EndChangeCheck())
        {
            Undo.RecordObject(luzManager, "Adjust Directional Light Direction");
            luzManager._DirectionalLightDirection = newDirDir - luzManager.transform.position;
            luzManager.UpdateAllMaterials();
        }

        // --- Spot Light Position ---
        EditorGUI.BeginChangeCheck();
        Vector3 newSpotPos = Handles.PositionHandle(luzManager._SpotLightPosition, Quaternion.identity);
        if (EditorGUI.EndChangeCheck())
        {
            Undo.RecordObject(luzManager, "Move Spot Light");
            luzManager._SpotLightPosition = newSpotPos;
            luzManager.UpdateAllMaterials();
        }

        // --- Spot Light Direction as Rotation ---
        EditorGUI.BeginChangeCheck();
        Vector3 currentDir = luzManager._SpotLightDirection.normalized;
        Quaternion currentRotation = Quaternion.LookRotation(currentDir);
        Quaternion newRotation = Handles.RotationHandle(currentRotation, luzManager._SpotLightPosition);
        if (EditorGUI.EndChangeCheck())
        {
            Undo.RecordObject(luzManager, "Rotate Spot Light Direction");
            luzManager._SpotLightDirection = newRotation * Vector3.forward * luzManager._SpotLightDirection.magnitude;
            luzManager.UpdateAllMaterials();
        }

        // Opcional: dibujar líneas para visual feedback
        Handles.color = Color.yellow;
        Handles.DrawLine(luzManager._SpotLightPosition, luzManager._SpotLightPosition + luzManager._SpotLightDirection);
        Handles.color = Color.cyan;
        Handles.DrawLine(luzManager.transform.position, luzManager.transform.position + luzManager._DirectionalLightDirection);
    }
}
