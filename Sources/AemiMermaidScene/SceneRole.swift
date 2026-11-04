/// What a shape, path or text is for. A backend maps a role to a style, so a theme or an appearance change redraws a scene without laying it out again.
public enum SceneRole: UInt8, Sendable, Equatable {
    case node, nodeAlt
    case edge, edgeAlt
    case label, labelBackground
    case cluster, clusterTitle
    case note, activation
    case accent0, accent1, accent2, accent3, accent4, accent5, accent6, accent7
    case danger, muted
}
