using UnityEngine;

namespace Pcfx
{
    [ExecuteInEditMode]
    class PointCloudRenderer : MonoBehaviour
    {
        [SerializeField] Vector3 _positionOffset = Vector3.zero;
        [SerializeField] Vector3 _rotationOffset = Vector3.zero;
        [SerializeField] Mesh _mesh = null;
        [SerializeField, ColorUsage(false, true)] Color _emissionColor1 = Color.red;
        [SerializeField, ColorUsage(false, true)] Color _emissionColor2 = Color.blue;
        [SerializeField, ColorUsage(false, true)] Color _emissionColor3 = Color.green;
        [SerializeField] float _pointSize = 0.01f;

        [SerializeField, HideInInspector] Shader _shader = null;

        Material _material;

        float LocalTime { get {
            return Application.isPlaying ? Time.time : 0;
        } }

        void OnDestroy()
        {
            Utility.Destroy(_material);
        }

        void Update()
        {
            if (_mesh == null) return;

            if (_material == null)
            {
                _material = new Material(_shader);
                _material.hideFlags = HideFlags.DontSave;
            }

            _material.SetMatrix("_Offset", Matrix4x4.TRS(
                _positionOffset, Quaternion.Euler(_rotationOffset), Vector3.one
            ));

            _material.SetFloat("_PointSize", _pointSize);
            _material.SetColor("_Emission1", _emissionColor1);
            _material.SetColor("_Emission2", _emissionColor2);
            _material.SetColor("_Emission3", _emissionColor3);
            _material.SetFloat("_LocalTime", LocalTime);

            Graphics.DrawMesh(
                _mesh, transform.localToWorldMatrix,
                _material, gameObject.layer
            );
        }
    }
}
