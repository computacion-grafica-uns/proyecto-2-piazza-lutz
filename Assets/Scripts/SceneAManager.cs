using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;


public class SceneAManager : MonoBehaviour
{
    public Transform[] targets;         // Objetivos: plano y teteras
    public float distance = 50f;        // Distancia de la cámara al objetivo
    public float rotationSpeed = 65f;   // Velocidad de rotación orbital

    private int currentTargetIndex = 0; // Índice del objetivo actual
    private float currentAngle = 0f;

    public float zoomSpeed = 100f;       // Qué tan rápido hace zoom
    public float minDistance = 50f;     // Distancia mínima
    public float maxDistance = 500f;   // Distancia máxima


    void Start()
    {
        targets = GameObject.FindGameObjectsWithTag("FocusTarget")
            .OrderBy(obj => obj.name)
            .Select(obj => obj.transform)
            .ToArray();
    }

    void Update()
    {
        if (targets.Length == 0) return;
        if (currentTargetIndex == 0)
        {
            maxDistance = 500f;
            minDistance = 250f;
            zoomSpeed = 80f;
        }
        else
        {
            maxDistance = 150f;
            minDistance = 30f;
            zoomSpeed = 50f;
        }

        // Cambiar de objetivo al presionar tecla
        if (Input.GetKeyDown(KeyCode.Tab))
        {
            if (Input.GetKey(KeyCode.LeftShift))
            {
                currentTargetIndex = (currentTargetIndex - 1) % targets.Length;
            }
            else
            {
                currentTargetIndex = (currentTargetIndex + 1) % targets.Length;
            }
        }

        // Zoom con la rueda del mouse
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        distance -= scroll * zoomSpeed;
        distance = Mathf.Clamp(distance, minDistance, maxDistance);

        // Girar alrededor del objetivo actual
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            currentAngle += rotationSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            currentAngle -= rotationSpeed * Time.deltaTime;
        }

        float rad = currentAngle * Mathf.Deg2Rad;

        Vector3 direction = new Vector3(Mathf.Sin(rad), 0.7f, Mathf.Cos(rad));
        Vector3 offset = direction * distance;
        transform.position = targets[currentTargetIndex].position + offset;
        transform.LookAt(targets[currentTargetIndex]);
    }
}
