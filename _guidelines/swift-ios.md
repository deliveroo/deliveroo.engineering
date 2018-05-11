---
layout:     guidelines
title:      "Swift & iOS"
subtitle:   "Guidelines on developing for iOS with Swift"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Views

### Subclassing `UIView`
{: #subclassing-uiview}

Create subviews by setting default property values, using closures for any required configuration.

**Preferred**
```swift
class MyView: UIView {
    
    let subview = UIView()

    let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Further initialisation
    }

}
```

**Not preferred**
```swift
class MyView: UIView {
    
    let subview: UIView

    let label: UILabel

    override init(frame: CGRect) {
        self.subview = UIView()
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        self.label = label
        super.init(frame: frame)
        // Further initialisation
    }
    
}
```
