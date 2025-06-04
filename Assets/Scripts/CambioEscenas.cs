using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement; // Necesario para la gestion de escenas

public class CambioEscenas : MonoBehaviour
{
    public static int numeroEscena = 0;

    void Start()
    {
        
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.L))
        {
            CambiarEscena(numeroEscena);
            numeroEscena = numeroEscena == 0 ? 1 : 0;
        }
       
    }

    private void CambiarEscena(int numero)
    {
        SceneManager.LoadScene(numero);
    }

}