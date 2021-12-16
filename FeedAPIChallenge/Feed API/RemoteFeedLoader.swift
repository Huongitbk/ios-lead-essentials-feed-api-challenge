//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	private final let HTTP_200_OK: Int = 200
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		// Step 1: Call get method
		client.get(from: url) { [weak self] Result in
			if (self == nil) { return; }
			// Step 2: Handle result from get method.
			switch (Result) {
			case let .success((data, response)):
				// Step 3: Decode returned data
				completion(self!.handleSuccessResponse(data: data, response: response))
			case .failure(_):
				completion(.failure(Error.connectivity))
				break;
			}
		}
	}
	// MARK - Private
	private func handleSuccessResponse(data: Data, response: HTTPURLResponse) -> FeedLoader.Result{
		if response.statusCode == HTTP_200_OK {
			let root = try? JSONDecoder().decode(Root.self, from: data);
			if (root != nil) {
				return .success(root!.items.map { item in
					return item.mapFeedImage();
				})
			} else {
				return .failure(Error.invalidData)
			}
		} else {
			return .failure(Error.invalidData)
		}
	}
}

private struct Root: Decodable {
	public let items: [FeedImageDecodable];
}

private struct FeedImageDecodable: Decodable {
	private let image_id: UUID
	private let image_desc: String?
	private let image_loc: String?
	private let image_url: URL

	public func mapFeedImage() -> FeedImage {
		return FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url);
	}
}
