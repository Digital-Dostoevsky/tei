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

The ```<persName>``` tag was filled in by XML identifiers and information about what kind/part of a name was being used: first names, patronymics, last names, diminutives, epithets, and nicknames. XML ID practices differed depending on what parts of a name were available. Characters with first name, last name, and patronymic were assigned three initials, for example, "amd" for Arkady Makarovich Dolgoruky. 

“Men” and “women” that do carry out individual actions are contrasted to groups of people that do not, for example monks that are only talked about/to as a unit and not as individuals. For these instances we created person group tags. Whenever a group of characters appeared under one name, it was assigned an XML ID beginning with grp and ending with the first three letters of the characters' surname, such as "grpver" for gospoda Versilovy. 

Some characters in the novel, even if they have names (which is not always the case), are primarily referred to by their professions or titles (certain monks, judges, bailiffs, etc.). For these characters, their professions/titles followed by p are their XML ID, i.e. "slugp" for sluga (servant).

Some names in the text are not tagged as characters at all (that is, they do not get an XML ID). These are minor characters/figures that never speak or are spoken to or that really play no significant role in the text. Any names like this are simply wrapped in a ```<persName>``` tag with no further identifiers. 

The back matter organizes names into different categories/types of characters. These are: fictional Dostoevsky, fictional non-Dostoevsky, mythical, historical, legendary (names that appear in stories, such as in Ivan’s Grand Inquisitor), imagined, and other (which primarily includes religious figures).

## Places

Places are tagged more or less in the same way as person names. Each place receives an XML ID, and all places are grouped into different categories in the back matter. These categories are: city, street, building, bridge, river, lake, country, island, station, historical entity (for states/countries no longer in existence), fictional Dostoevsky, fictional non-Dostoevsky, imagined, mythical, cosmic, region, monastery, administrative division, legendary, and other. 

## Speech

Most of speech tagging was straightforward in this novel, though there are a few peculiarities. 

For instance, specific XML IDs were assigned for the imagined reader and the imagined interlocutor in instances where Arkady or another character either addresses the reader directly or has another unidentified imaginary listener. For instance: 

```xml
Но если б я не знал портрета и после этих трех минут спросили меня: <said aloud="false" direct="false" who="#imintp" toWhom="#amd">«Какая она?»</said> — я бы ничего не ответил, потому что всё у меня заволоклось."
```

We also have ```<seg type=“imaginary”>``` when a character imagines the speech of another character. For example, here is a passage where Efim is talking to Arkady about a possible conversation with Knyaz Sergey:  

```xml
И вдруг князь меня спросит: <seg type="imaginary"><said aloud="false" direct="true" who="#knser" toWhom="#efz">«Вас кто прислал?»</said></seg>"
```
There are many instances of speech where multiple addressees are present. These are tagged in the following way (as an example): ```<who=“#dfk” toWhom= “afk” “aas”>```

Finally, there are a couple instances where speech not assignable to particular people is more or less just floating around – that is, there is dialogue, but there is no indication who specifically is speaking or being spoken to. In these cases speech is tagged without a who or toWhom. 



