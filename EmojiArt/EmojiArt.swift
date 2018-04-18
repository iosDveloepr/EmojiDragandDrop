//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Yermakov Anton on 01.03.2018.
//  Copyright © 2018 Yermakov Anton. All rights reserved.
//

import Foundation

struct EmojiArt: Codable
{
    
    var url: URL
    var emojis = [EmojiInfo]()
    
    struct EmojiInfo: Codable {
        var x: Int
        var y: Int
        var text: String
        var size: Int
    }
    
    init?(json: Data){
        if let newValue = try? JSONDecoder().decode(EmojiArt.self, from: json){
            self = newValue
        } else {
            return nil
        }
    }
    
    var json: Data?{
        return try? JSONEncoder().encode(self)
    }
    
    init(url: URL, emojis: [EmojiInfo]){
        self.url = url
        self.emojis = emojis
    }
}
