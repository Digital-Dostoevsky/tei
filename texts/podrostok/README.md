# podrostok

This readme file was generated on [2024-10-20] by [Veronika Sizova]

## Automated Tagging

The first round of tagging was completed by developer Simon Wiles. Simon automated the initial steps of name tagging, place tagging, and speech tagging. For name tagging, Simon wrapped in a simple <persName> tag any name that appeared in the novel. (He was provided with a list of names beforehand.) The process for tagging places – with the <placeName> tag – was essentially the same (Simon was also provided with a list of places beforehand). Lastly, Simon automated the basic tagging of speech by encoding what appeared to be instances of speech (strings of text set off by specific punctuation) in the following way: 

```xml
<said aloud=“” direct=“” who=“” toWhom=“”>[text goes here]</said>.
```

Automated name and place tagging was mostly successful. Only the occasional name or place was missed, and very rarely was something that was not a name or a place tagged as if it was. For example: sometimes capitalized words at the beginning of a sentence – e.g. “Барин” – were falsely tagged as person names.

Automated speech tagging was a little more complicated due to the patterning of punctuation markings. Not infrequently were passages of text marked erroneously. Moreover, closing speech tags ```(</said>)``` had a tendency to appear in the wrong places. Complications arose too in instances where there was speech inside of speech. In general, though, any problems with automated tagging of speech could be easily addressed by paying close attention while reading. 

After the automated tagging, our next step was to manually populate the blank spaces in ```<persName>```, ```<placeName>```, and ```<said>``` tags.

## Names

The ```<persName>``` tag was filled in by XML identifiers and information about what kind/part of a name was being used: first names, patronymics, last names, diminutives, epithets, and nicknames. XML ID practices differed depending on what parts of a name were available. Characters with first name, last name, and patronymic were assigned three initials, for example, "amd" for Arkadiy Makarovich Dolgoruky. Whenever a group of characters appeared under one name, it was assigned an XML ID beginning with grp and ending with the first three letters of the characters' surname, such as "grpver" for gospoda Versilovy. 