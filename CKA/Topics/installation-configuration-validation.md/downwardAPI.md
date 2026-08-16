# Downward API

The **Downward API** allows a container to access information about itself or the Pod it is running in **without directly calling the Kubernetes API**.

It keeps applications loosely coupled to Kubernetes while still providing useful runtime metadata.

## What Can It Provide?

- Pod name
- Pod namespace
- Pod IP
- Node name
- Labels and annotations
- CPU and memory requests/limits

## Common Use Cases

- **Logging and tracing** → Add Pod name, namespace, or node name to logs.
- **Service discovery** → Use Pod name or namespace as an identifier.
- **Resource awareness** → Make CPU/memory requests or limits available to the application.

## How It Is Exposed

### Environment Variables

Useful for small and simple values.

    env:
      - name: POD_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.name

### Mounted Files

Useful for labels, annotations, or other metadata that is better consumed as files.

    volumes:
      - name: podinfo
        downwardAPI:
          items:
            - path: labels
              fieldRef:
                fieldPath: metadata.labels

## fieldRef vs resourceFieldRef

| Type | Used For |
|---|---|
| `fieldRef` | Pod/metadata information |
| `resourceFieldRef` | Container resource information |
| `downwardAPI` volume | Exposing metadata as files |

## Divisor

`divisor` is used with `resourceFieldRef`.

It controls the unit in which a resource amount is exposed to the application.

For example, CPU can be exposed in cores or millicores depending on the divisor.

    Resource amount
          ↓
       Divisor
          ↓
    Value exposed to application

## Remember

    fieldRef          → Pod/metadata information
    resourceFieldRef  → Container resource information
    downwardAPI       → Expose metadata through a volume